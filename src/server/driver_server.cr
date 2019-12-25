require "./client"
require "../reql/*"
require "json"
require "../crypto"

module RethinkDB
  module Server
    class DriverServer
      V0_1 = 0x3f61ba36_u32
      V0_2 = 0x723081e1_u32
      V0_3 = 0x5f75e83e_u32
      V0_4 = 0x400c2d20_u32
      V1_0 = 0x34c2bdc3_u32

      def initialize(@port : Int32, @conn : RethinkDB::Connection)
        @server = TCPServer.new(@port)
        @wants_close = false
      end

      def start
        spawn do
          until @wants_close
            sock = begin
              @server.try &.accept?
            rescue err
              err.inspect_with_backtrace
              nil
            end

            if sock
              # a non nillable version of the closured sock
              _sock = sock
              spawn handle_client(_sock)
            end
          end
        end
      end

      def close
        @wants_close = true
        if server = @server
          server.close
          @server = nil
        end
      end

      private def handle_client(sock)
        sock.sync = false
        remote_address = sock.remote_address

        protocol_version = sock.read_bytes(UInt32, IO::ByteFormat::LittleEndian)

        if protocol_version != V1_0
          sock.write("ERROR: Received an unsupported protocol version. This port is for RethinkDB queries. Does your client driver version not match the server?\0".to_slice)
          sock.close
          return
        end

        sock.write(({
          success:              true,
          min_protocol_version: 0,
          max_protocol_version: 0,
          server_version:       "0.0.0",
        }.to_json + "\0").to_slice)
        sock.flush

        first_auth_message = sock.gets('\0', true)
        unless first_auth_message
          sock.write("ERROR: Auth message was not received.\0".to_slice)
          sock.close
          return
        end
        first_auth_message = JSON.parse first_auth_message

        if first_auth_message["protocol_version"] != 0
          sock.write("ERROR: Unsupported `protocol_version`.\0".to_slice)
          sock.close
          return
        end

        if first_auth_message["authentication_method"] != "SCRAM-SHA-256"
          sock.write("ERROR: Unsupported `authentication_method`.\0".to_slice)
          sock.close
          return
        end

        message1 = first_auth_message["authentication"].as_s
        message1 =~ /n,,n=([^,]+),r=([^,]+)/

        username = $1
        nonce_c = $2

        password = ""
        salt = Random::Secure.random_bytes(16)
        iter = 1024
        nonce_s = Random::Secure.base64(18)
        password_hash = pbkdf2_hmac_sha256(password.to_slice, salt, iter)

        message2 = "r=#{nonce_c}#{nonce_s},s=#{Base64.strict_encode(salt)},i=#{iter}"

        sock.write(({
          success:        true,
          authentication: message2,
        }.to_json + "\0").to_slice)
        sock.flush

        final_auth_message = sock.gets('\0', true)
        unless final_auth_message
          sock.write("ERROR: Auth message was not received.\0".to_slice)
          sock.close
          return
        end
        final_auth_message = JSON.parse final_auth_message

        message3 = final_auth_message["authentication"].as_s

        client_key = hmac_sha256(password_hash, "Client Key")
        stored_key = sha256(client_key)
        auth_message = message1[3..-1] + "," + message2 + "," + message3.sub(/,p=([^,]+)/, "")
        client_signature = hmac_sha256(stored_key, auth_message)
        client_proof = Bytes.new(client_signature.size)
        client_proof.size.times do |i|
          client_proof[i] = client_key[i] ^ client_signature[i]
        end

        message3 =~ /c=biws,r=#{Regex.escape nonce_c + nonce_s},p=([^,]+)/
        sent_client_proof = Base64.decode($1)

        if client_proof != sent_client_proof
          sock.write(({
            success:    false,
            error:      "Wrong password",
            error_code: 1,
          }.to_json + "\0").to_slice)
          sock.close
          return
        end

        server_key = hmac_sha256(password_hash, "Server Key")
        server_signature = hmac_sha256(server_key, auth_message)

        message4 = "v=#{Base64.strict_encode server_signature}"

        sock.write(({
          success:        true,
          authentication: message4,
        }.to_json + "\0").to_slice)
        sock.flush

        # puts "Accepted connection from #{remote_address}."
        client = Client.new(@conn)

        response_channel = Channel({UInt64, String}).new
        spawn do
          while tup = response_channel.receive?
            query_token = tup[0]
            answer_json = tup[1]

            sock.write_bytes(query_token, IO::ByteFormat::LittleEndian)
            sock.write_bytes(answer_json.bytesize, IO::ByteFormat::LittleEndian)
            sock.write(answer_json.to_slice)
            sock.flush
          end
        end

        until sock.closed?
          query_token = sock.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
          query_length = sock.read_bytes(UInt32, IO::ByteFormat::LittleEndian)

          query_bytes = Bytes.new(query_length)
          sock.read_fully(query_bytes)

          spawn execute_query(client.not_nil!, query_bytes, query_token, response_channel)
        end
      rescue IO::EOFError
        # This is expected when client closes the connection
      rescue err : Errno
        err.inspect_with_backtrace
      ensure
        client.try &.close
        if sock
          # puts "Disconnected from #{remote_address}."
          sock.close
        end
      end

      def execute_query(client, query_bytes, query_token, response_channel)
        message_json = String.new(query_bytes)
        message = JSON.parse(message_json).as_a
        answer = client.execute(query_token, message)
        answer_json = answer.to_json
        response_channel.send({query_token, answer_json})
      end
    end
  end
end
