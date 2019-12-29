require "./server/*"
require "./driver/*"

include RethinkDB::DSL

conn = r.local_database("./data")

webui_server = RethinkDB::Server::WebUiServer.new(8080, conn)
webui_server.start

driver_server = RethinkDB::Server::DriverServer.new(28015, conn)
driver_server.start

puts "Listening for administrative HTTP connections on http://localhost:8080/"
puts "Listening for client driver connections on port 28015"
puts "Server #{conn.server["name"].inspect} (#{conn.server["id"]}) ready."

Signal::INT.trap do
  puts "Server got SIGINT; shutting down..."
  exit
end

at_exit do
  puts "Shutting down client connections..."
  webui_server.close
  driver_server.close
  puts "All client connections closed."
  puts "Shutting down storage engine... (This may take a while if you had a lot of unflushed data in the writeback cache.)"
  conn.close
  puts "Storage engine shut down."
end

sleep
