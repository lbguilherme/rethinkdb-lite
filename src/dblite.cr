require "./storage/*"
require "./server/*"

require "file_utils"

f = "/home/guilherme/test.db"

if File.exists? f
  FileUtils.rm f
end
if File.exists? "#{f}.wal"
  FileUtils.rm "#{f}.wal"
end

Server.start_http

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
