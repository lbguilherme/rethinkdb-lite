require "./storage/*"
require "./server/*"
require "./reql/*"

require "file_utils"

f = "/home/guilherme/test.db"

if File.exists? f
  FileUtils.rm f
end
if File.exists? "#{f}.wal"
  FileUtils.rm "#{f}.wal"
end

r.table_create("a").run
r.table_create("b").run
r.table_create("c").run
r.db_create("foo").run
r.db("foo").table_create("bar").run
r.db("foo").table_create("baz").run

Server::HttpServer.new(8080).start
puts "Server #{Storage::Config.server_info.name.inspect} (#{Storage::Config.server_info.id}) ready."

sleep

# table = Table.create(f)

# count = 0
# s = Time.now
# while true

#   ss = Time.now
#   1000.times do
#     obj = {"id" => count += 1}
#     table.insert(obj)
#   end
#   # p (Time.now-ss).to_f
#   puts [count, Time.now-s, 1000.0/(Time.now-ss).to_f]
# end

include ReQL::DSL

p r.table("weibc").get("odcbwo").run
