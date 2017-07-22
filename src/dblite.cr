require "./storage/*"


require "file_utils"

if File.exists? "test.db"
  FileUtils.rm "test.db"
end
if File.exists? "test.db.wal"
  FileUtils.rm "test.db.wal"
end


db = DatabaseFile.create("test.db")

db.write do |writter|
  writter.alloc('E')
end

db.write do |writter|
  writter.alloc('E')
  writter.alloc('E')
  writter.del(1u32)
  writter.alloc('E')
end

db.debug
p db

# db = DatabaseFile.open("test.db")
# db.debug
# p db
#p db.read_page(3u32)

