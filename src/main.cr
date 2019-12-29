require "./server/*"
require "./driver/*"

include RethinkDB::DSL

conn = r.local_database("./data")

RethinkDB::Server::WebUiServer.new(8080, conn).start
RethinkDB::Server::DriverServer.new(28015, conn).start

puts "Listening for administrative HTTP connections on http://localhost:8080/"
puts "Listening for client driver connections on port 28015"
puts "Server #{conn.server["name"].inspect} (#{conn.server["id"]}) ready."

Signal::INT.trap do
  puts "Server got SIGINT"
  exit
end

at_exit do
  puts "Shutting down... (This may take a while if you had a lot of unflushed data in the writeback cache.)"
  conn.close
end

sleep
