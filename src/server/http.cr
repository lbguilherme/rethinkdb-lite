require "./connection"
require "../reql/*"
require "http/server"
require "json"
require "http/server/handlers/static_file_handler"

module Server
  @@http_connections = {} of String => ClientConnection

  def self.start_http
    static_handler = HTTP::StaticFileHandler.new("vendor/rethinkdb-webui/dist/", false, false)
    server = HTTP::Server.new(8080) do |context|
      uri = URI.parse(context.request.resource)
      case uri.path
      when "/ajax/reql/open-new-connection"
        conn_id = SecureRandom.base64
        @@http_connections[conn_id] = ClientConnection.new
        context.response.print conn_id
      when "/ajax/reql/close-connection"
        conn_id = (uri.query || "").sub("conn_id=", "")
        conn = @@http_connections[conn_id]?
        if conn
          conn.streams.values.each &.finish_reading
        end
        @@http_connections.delete conn_id
      when "/ajax/reql/"
        conn_id = (uri.query || "").sub("conn_id=", "")
        conn = @@http_connections[conn_id]?
        unless conn
          context.response.status_code = 400
          next
        end
        body = context.request.body || IO::Memory.new
        query_id = body.read_bytes(UInt64)
        puts "-------------------------------------------------------------------"
        message_json = body.gets_to_end
        puts message_json
        message = JSON.parse(message_json).raw.as(Array)
        answer = "{}"
        begin
          start = Time.now
          case message[0]
          when 1 # START
            query = ReQL::Query.new(query_id, message[1], message[2]?.as(Hash(String, JSON::Type) | Nil))
            result = query.run
            if result.is_a? ReQL::Datum
              answer = {
                "t" => 1,
                "r" => [result.value],
                "p" => [{"duration(ms)" => (Time.now - start).to_f * 1000}],
                "n" => [] of String,
              }.to_json
            elsif result.is_a? ReQL::Stream
              result.start_reading
              conn.streams[query_id] = result
              list = [] of ReQL::Datum::Type
              has_more = true
              40.times do
                tup = result.next_val
                unless tup
                  conn.streams.delete query_id
                  result.finish_reading
                  has_more = false
                  break
                end
                list << tup[0]
              end
              answer = {
                "t" => has_more ? 3 : 2,
                "r" => list,
                "p" => [{"duration(ms)" => (Time.now - start).to_f * 1000}],
                "n" => [] of String,
              }.to_json
            else
              raise ReQL::RuntimeError.new("Odd... this query returned neither a datum nor a stream")
            end
          when 2 # CONTINUE
            result = conn.streams[query_id]?
            list = [] of ReQL::Datum::Type
            has_more = true
            if result
              40.times do
                tup = result.next_val
                unless tup
                  conn.streams.delete query_id
                  result.finish_reading
                  has_more = false
                  break
                end
                list << tup[0]
              end
            else
              has_more = false
            end
            answer = {
              "t" => has_more ? 3 : 2,
              "r" => list,
              "p" => [{"duration(ms)" => (Time.now - start).to_f * 1000}],
              "n" => [] of String,
            }.to_json
          when 3 # STOP
            result = conn.streams[query_id]?
            if result
              conn.streams.delete query_id
              result.finish_reading
            end
            answer = {
              "t" => 2,
              "r" => [] of String,
              "p" => [{"duration(ms)" => (Time.now - start).to_f * 1000}],
              "n" => [] of String,
            }.to_json
          when 4 # NOREPLY_WAIT
          when 5 # SERVER_INFO
            info = {
              "id"    => SecureRandom.uuid,
              "name"  => "Crystal Rethink",
              "proxy" => false,
            }
            answer = {"t" => 5, "r" => [info], "p" => [{"duration(ms)" => 0}]}.to_json
          end
        rescue ex : ReQL::CompileError
          answer = {"t" => 17, "r" => [ex.message], "b" => [] of String}.to_json
        rescue ex : ReQL::RuntimeError
          answer = {"t" => 18, "r" => [ex.message], "b" => [] of String}.to_json
        end
        puts answer
        context.response.write_bytes(query_id)
        context.response.write_bytes(answer.size)
        context.response.print answer
      else
        if context.request.path == "/"
          context.request.path = "/index.html"
        end
        static_handler.call(context)
      end
    end

    puts "Listening on http://127.0.0.1:8080"
    server.listen
  end
end
