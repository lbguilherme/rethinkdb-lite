require "./connection"
require "../reql/*"
require "json"
require "../crypto"

module Server
  class DriverServer
    V0_1 = 0x3f61ba36_u32
    V0_2 = 0x723081e1_u32
    V0_3 = 0x5f75e83e_u32
    V0_4 = 0x400c2d20_u32
    V1_0 = 0x34c2bdc3_u32

    def initialize(@port : Int32)
      @server = TCPServer.new(@port)
      @wants_close = false
    end

    def start
      puts "Listening for client driver connections on port #{@port}/"
      spawn do
        until @wants_close
          spawn handle_client(@server.try &.accept?)
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

    private def handle_client(io)
      return unless io
      remote_address = io.remote_address

      protocol_version_magic = Bytes.new(4)
      io.read(protocol_version_magic)
      protocol_version = IO::ByteFormat::LittleEndian.decode(UInt32, protocol_version_magic)

      if protocol_version != V1_0
        io.write("ERROR: Received an unsupported protocol version. This port is for RethinkDB queries. Does your client driver version not match the server?\0".to_slice)
        io.close
        return
      end

      io.write(({
        success:              true,
        min_protocol_version: 0,
        max_protocol_version: 0,
        server_version:       "0.0.0",
      }.to_json + "\0").to_slice)

      first_auth_message = io.gets('\0', true)
      unless first_auth_message
        io.write("ERROR: Auth message was not received.\0".to_slice)
        io.close
        return
      end
      first_auth_message = JSON.parse first_auth_message

      if first_auth_message["protocol_version"] != 0
        io.write("ERROR: Unsupported `protocol_version`.\0".to_slice)
        io.close
        return
      end

      if first_auth_message["authentication_method"] != "SCRAM-SHA-256"
        io.write("ERROR: Unsupported `authentication_method`.\0".to_slice)
        io.close
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

      message2 = "r=#{nonce_c}#{nonce_s},s=#{Base64.encode(salt)},i=#{iter}"

      io.write(({
        success:        true,
        authentication: message2,
      }.to_json + "\0").to_slice)

      final_auth_message = io.gets('\0', true)
      unless final_auth_message
        io.write("ERROR: Auth message was not received.\0".to_slice)
        io.close
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
        io.write(({
          success:    false,
          error:      "Wrong password",
          error_code: 1,
        }.to_json + "\0").to_slice)
        io.close
        return
      end

      server_key = hmac_sha256(password_hash, "Server Key")
      server_signature = hmac_sha256(server_key, auth_message)

      message4 = "v=#{Base64.encode server_signature}"

      io.write(({
        success:        true,
        authentication: message4,
      }.to_json + "\0").to_slice)

      # puts "Accepted connection from #{remote_address}."
      conn = ClientConnection.new

      sock = io

      until sock.closed?
        query_token = sock.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
        query_length_bytes = sock.read_bytes(UInt32, IO::ByteFormat::LittleEndian)

        query_bytes = Bytes.new(query_length)
        offset = 0
        while offset < query_length
          read = sock.read(query_bytes[offset, query_length - offset])
          break if read == 0
          offset += read
        end
        break unless offset == query_length

        spawn do
          message_json = String.new(query_bytes)
          message = JSON.parse(message_json).as_a
          answer = conn.execute(query_token, message)

          sock.write_bytes(query_token, IO::ByteFormat::LittleEndian)
          sock.write_bytes(answer.bytesize, IO::ByteFormat::LittleEndian)
          sock.write(answer.to_slice)

          sock.flush
        end
      end
    rescue err : Errno
      err.inspect_with_backtrace
    ensure
      if io
        # puts "Disconnected from #{remote_address}."
        io.close
      end
    end
  end
end
