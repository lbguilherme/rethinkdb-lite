require "socket"
require "../crypto"

module RethinkDB
  class RemoteConnection < Connection
    V0_1 = 0x3f61ba36_u32
    V0_2 = 0x723081e1_u32
    V0_3 = 0x5f75e83e_u32
    V0_4 = 0x400c2d20_u32
    V1_0 = 0x34c2bdc3_u32

    @channels = {} of UInt64 => Channel(String)
    @next_query_id = 1_u64

    def initialize(host : String, port : Int)
      @socket = TCPSocket.new(host, port)

      protocol_version_bytes = Bytes.new(4)
      IO::ByteFormat::LittleEndian.encode(V1_0, protocol_version_bytes)
      @socket.write(protocol_version_bytes)

      @socket.gets('\0', true)
    end

    def close
      @socket.close
    end

    # TODO: Proper error handling
    def authorize(user : String, password : String)
      nonce_c = Random::Secure.base64(14)

      message1 = "n,,n=#{user},r=#{nonce_c}"

      @socket.write(({
        protocol_version:      0,
        authentication_method: "SCRAM-SHA-256",
        authentication:        message1,
      }.to_json + "\0").to_slice)

      json = JSON.parse(@socket.gets('\0', true).not_nil!)
      message2 = json["authentication"].as_s

      message2 =~ /r=#{Regex.escape nonce_c}([^,]+),s=([^,]+),i=(\d+)/
      nonce_s = $1
      salt = Base64.decode($2)
      iter = $3.to_i

      password_hash = pbkdf2_hmac_sha256(password.to_slice, salt, iter)

      message3_start = "c=biws,r=#{nonce_c}#{nonce_s}"

      client_key = hmac_sha256(password_hash, "Client Key")
      stored_key = sha256(client_key)
      auth_message = message1[3..-1] + "," + message2 + "," + message3_start
      client_signature = hmac_sha256(stored_key, auth_message)
      client_proof = Bytes.new(client_signature.size)
      client_proof.size.times do |i|
        client_proof[i] = client_key[i] ^ client_signature[i]
      end

      message3 = "c=biws,r=#{nonce_c}#{nonce_s},p=#{Base64.strict_encode(client_proof)}"

      @socket.write(({
        authentication: message3,
      }.to_json + "\0").to_slice)

      json = JSON.parse(@socket.gets('\0', true).not_nil!)
      unless json["success"]
        raise "Auth fail"
      end
    end

    def use(db_name : String)
    end

    def start
      spawn do
        until @socket.closed?
          id = @socket.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
          size = @socket.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
          slice = Slice(UInt8).new(size)
          @socket.read(slice)
          @channels[id]?.try &.send String.new(slice)
        end
      end
    end

    def run(term : ReQL::Term::Type, runopts : RunOpts) : RethinkDB::Cursor | RethinkDB::Datum
      query = Query.new(self, runopts)
      response = query.start(term)

      case response.t
      when ResponseType::SUCCESS_ATOM
        return Datum.new(response.r[0].raw, runopts)
      when ResponseType::SUCCESS_SEQUENCE, ResponseType::SUCCESS_PARTIAL
        return Cursor.new(query, response, runopts)
      else
        raise "TODO"
      end
    end

    def server : JSON::Any
      query = Query.new(self, RunOpts.new)
      response = query.server_info

      case response.t
      when ResponseType::SERVER_INFO
        return response.r[0]
      else
        raise "TODO"
      end
    end

    protected def next_query_id
      id = @next_query_id
      @next_query_id += 1
      id
    end

    enum QueryType
      START        = 1
      CONTINUE     = 2
      STOP         = 3
      NOREPLY_WAIT = 4
      SERVER_INFO  = 5
    end

    enum ResponseType
      SUCCESS_ATOM     =  1
      SUCCESS_SEQUENCE =  2
      SUCCESS_PARTIAL  =  3
      WAIT_COMPLETE    =  4
      SERVER_INFO      =  5
      CLIENT_ERROR     = 16
      COMPILE_ERROR    = 17
      RUNTIME_ERROR    = 18
    end

    enum ErrorType
      INTERNAL         = 1000000
      RESOURCE_LIMIT   = 2000000
      QUERY_LOGIC      = 3000000
      NON_EXISTENCE    = 3100000
      OP_FAILED        = 4100000
      OP_INDETERMINATE = 4200000
      USER             = 5000000
      PERMISSION_ERROR = 6000000
    end

    class Response
      JSON.mapping({
        t: ResponseType,
        r: Array(JSON::Any),
        e: {type: ErrorType, nilable: true},
        b: {type: Array(JSON::Any), nilable: true},
        p: {type: JSON::Any, nilable: true},
        n: {type: Array(Int32), nilable: true},
      })
    end

    class Query
      getter id : UInt64
      @channel : Channel(String)

      def initialize(@conn : RemoteConnection, @runopts : RunOpts)
        @id = @conn.next_query_id
        @channel = @conn.@channels[id] = Channel(String).new
      end

      def server_info
        send [QueryType::SERVER_INFO].to_json
        read
      end

      def start(term)
        send [QueryType::START, ReQL::Term.encode(term), @runopts].to_json
        read
      end

      def continue
        send [QueryType::CONTINUE].to_json
        read
      end

      private def send(query)
        if @id == 0
          raise "Bug: Using already finished stream."
        end

        @conn.@socket.write_bytes(@id, IO::ByteFormat::LittleEndian)
        @conn.@socket.write_bytes(query.bytesize, IO::ByteFormat::LittleEndian)
        @conn.@socket.write(query.to_slice)
      end

      private def read
        response = Response.from_json(@channel.receive)
        finish unless response.t == ResponseType::SUCCESS_PARTIAL

        if response.t == ResponseType::CLIENT_ERROR
          raise ReQL::ClientError.new(response.r[0].to_s)
        elsif response.t == ResponseType::COMPILE_ERROR
          raise ReQL::CompileError.new(response.r[0].to_s)
        elsif response.t == ResponseType::RUNTIME_ERROR
          msg = response.r[0].to_s
          case response.e
          when ErrorType::INTERNAL        ; raise ReQL::InternalError.new msg
          when ErrorType::RESOURCE_LIMIT  ; raise ReQL::ResourceLimitError.new msg
          when ErrorType::QUERY_LOGIC     ; raise ReQL::QueryLogicError.new msg
          when ErrorType::NON_EXISTENCE   ; raise ReQL::NonExistenceError.new msg
          when ErrorType::OP_FAILED       ; raise ReQL::OpFailedError.new msg
          when ErrorType::OP_INDETERMINATE; raise ReQL::OpIndeterminateError.new msg
          when ErrorType::USER            ; raise ReQL::UserError.new msg
          when ErrorType::PERMISSION_ERROR; raise ReQL::PermissionError.new msg
          else
            raise ReQL::RuntimeError.new(response.e.to_s + ": " + msg)
          end
        end

        # response.r = response.r.map &.transformed(
        #   time_format: @runopts["time_format"]? || "native",
        #   group_format: @runopts["group_format"]? || "native",
        #   binary_format: @runopts["binary_format"]? || "native"
        # )

        response
      end

      private def finish
        @conn.@channels.delete @id
        @id = 0u64
      end
    end

    class Cursor < RethinkDB::Cursor
      def initialize(@query : Query, @response : Response, @runopts : RunOpts)
        @index = 0
      end

      def fetch_next
        @response = @query.continue
        @index = 0

        unless @response.t == ResponseType::SUCCESS_SEQUENCE || @response.t == ResponseType::SUCCESS_PARTIAL
          raise ReQL::RuntimeError.new("Expected SUCCESS_SEQUENCE or SUCCESS_PARTIAL but got #{@response.t}")
        end
      end

      def next
        while @index == @response.r.size
          return stop if @response.t == ResponseType::SUCCESS_SEQUENCE
          fetch_next
        end

        value = Datum.new @response.r[@index].raw, @runopts
        @index += 1
        return value
      end

      def close
        # TODO
      end
    end
  end
end
