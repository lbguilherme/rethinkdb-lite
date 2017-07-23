require "./connection"
require "../reql/*"
require "http/server"
require "json"

module Server
  @@http_connections = {} of String => ClientConnection

  def self.start_http
    server = HTTP::Server.new(8080) do |context|
      uri = URI.parse(context.request.resource)
      case uri.path
      when "/ajax/reql/open-new-connection"
        conn_id = SecureRandom.base64
        @@http_connections[conn_id] = ClientConnection.new
        context.response.print conn_id
      when "/ajax/reql/close-connection"
        conn_id = (uri.query || "").sub("conn_id=", "")
        @@http_connections.delete conn_id
      when "/ajax/reql/"
        conn_id = (uri.query || "").sub("conn_id=", "")
        conn = @@http_connections[conn_id]
        body = context.request.body || IO::Memory.new
        query_id = body.read_bytes(UInt64)
        message = JSON.parse(body.gets_to_end).raw.as(Array)
        case message[0]
        when 1 # START
          query = Query.new(query_id, message[1], message[2]?.as(Hash(String, JSON::Type) | Nil))
        when 2 # CONTINUE
        when 3 # STOP
        when 4 # NOREPLY_WAIT
        when 5 # SERVER_INFO
        end
        answer = {"t" => 18, "r" => ["hmm..."], "b" => [] of String}.to_json
        context.response.write_bytes(query_id)
        context.response.write_bytes(answer.size)
        context.response.print answer
      else
        p context.request
        context.response.status_code = 400
      end

      # res = HTTP::Client.new("172.17.0.2", 8080).exec(context.request)
      # p res.body
      # res.headers.each do |(k ,v)|
      #   context.response.headers[k] = v
      # end
      # context.response.status_code = res.status_code
      # context.response.print res.body
    end

    puts "Listening on http://127.0.0.1:8080"
    server.listen
  end
end
