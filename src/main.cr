require "./server/*"
require "./driver/*"
require "file_utils"
include RethinkDB::DSL

FileUtils.rm_rf "/tmp/rethinkdb-lite/data"
conn = r.local_database("/tmp/rethinkdb-lite/data")

r.table_create("a").run(conn)
r.table_create("b").run(conn)
r.table_create("c").run(conn)
r.db_create("foo").run(conn)
r.db("foo").table_create("bar").run(conn)
r.db("foo").table_create("baz").run(conn)

RethinkDB::Server::HttpServer.new(8080, conn).start
RethinkDB::Server::DriverServer.new(28015, conn).start

puts "Listening for administrative HTTP connections on http://localhost:8080/"
puts "Listening for client driver connections on port 28015"

# puts "Server #{Storage::Config.server_info.name.inspect} (#{Storage::Config.server_info.id}) ready."

sleep
