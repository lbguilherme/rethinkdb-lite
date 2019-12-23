require "./client"
require "../reql/*"
require "http/server"
require "json"
require "http/server/handlers/static_file_handler"

module RethinkDB
  module Server
    class HttpServer
      @clients = {} of String => Client

      def initialize(@port : Int32, @conn : RethinkDB::Connection)
        static_handler = HTTP::StaticFileHandler.new("vendor/rethinkdb-webui/dist/", false, false)
        @server = HTTP::Server.new do |context|
          uri = URI.parse(context.request.resource)
          case uri.path
          when "/ajax/reql/open-new-connection"
            conn_id = Random::Secure.base64
            @clients[conn_id] = Client.new(@conn)
            context.response.print conn_id
          when "/ajax/reql/close-connection"
            conn_id = (uri.query || "").sub("conn_id=", "")
            client = @clients[conn_id]?
            if client
              client.close
              @clients.delete conn_id
            end
          when "/ajax/reql/"
            conn_id = (uri.query || "").sub("conn_id=", "")
            client = @clients[conn_id]?
            unless client
              context.response.status_code = 400
              next
            end
            body = context.request.body || IO::Memory.new
            query_id = body.read_bytes(UInt64)
            message_json = body.gets_to_end

            message = JSON.parse(message_json).raw.as(Array)
            answer = client.execute(query_id, message)

            context.response.write_bytes(query_id)
            context.response.write_bytes(answer.bytesize)
            context.response.write(answer.to_slice)
          else
            if context.request.path == "/"
              context.request.path = "/index.html"
            end
            static_handler.call(context)
          end
        end
      end

      def start
        spawn do
          @server.listen(@port)
        end
      end

      def close
        @server.close
      end
    end
  end
end
