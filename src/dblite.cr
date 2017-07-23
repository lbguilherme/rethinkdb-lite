require "./storage/*"


require "file_utils"

if File.exists? "test.db"
  FileUtils.rm "test.db"
end
if File.exists? "test.db.wal"
  FileUtils.rm "test.db.wal"
end


db = DatabaseFile.create("test.db")

s=Time.now

table = Table.new(0u32)
db.write do |w|
  table = Table.create(w)

  5.times do |i|
    obj = {"id" => "#{i}", "str" => "Hello #{i}!"}
    table.insert(w, obj)
  end
end

db.read do |r|
  5.times do |i|
    p table.get(r, "#{i}")
  end
end
t=Time.now-s

db.debug
p t
