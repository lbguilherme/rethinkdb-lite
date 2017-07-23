require "./storage/*"


require "file_utils"

if File.exists? "test.db"
  FileUtils.rm "test.db"
end
if File.exists? "test.db.wal"
  FileUtils.rm "test.db.wal"
end


table = Table.create("test.db")
5.times do |i|
  obj = {"id" => "#{i}", "str" => "Hello #{i}!"}
  table.insert(obj)
end
5.times do |i|
  p table.get("#{i}")
end

p table
