require "./storage/*"


require "file_utils"

if File.exists? "test.db"
  FileUtils.rm "test.db"
end
if File.exists? "test.db.wal"
  FileUtils.rm "test.db.wal"
end


db = DatabaseFile.create("test.db")
db.allocate_page('E')
db.commit
db.allocate_page('E')
db.allocate_page('E')
db.delete_page(1u32)
db.allocate_page('E')
db.commit
db.debug
p db

# db = DatabaseFile.open("test.db")
# db.debug
# p db
#p db.read_page(3u32)

