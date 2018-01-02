require "./server/*"
require "./driver/*"
require "file_utils"
include RethinkDB::DSL

conn = r.local_database("/tmp/rethinkdb-lite/data")

Server::HttpServer.new(8080, conn).start
Server::DriverServer.new(28015, conn).start

# puts "Server #{Storage::Config.server_info.name.inspect} (#{Storage::Config.server_info.id}) ready."

sleep
