require "./storage/*"
require "./server/*"
require "./reql/*"

include ReQL::DSL

r.table_create("a").run
r.table_create("b").run
r.table_create("c").run
r.db_create("foo").run
r.db("foo").table_create("bar").run
r.db("foo").table_create("baz").run

Server::HttpServer.new(8080).start
puts "Server #{Storage::Config.server_info.name.inspect} (#{Storage::Config.server_info.id}) ready."

sleep
