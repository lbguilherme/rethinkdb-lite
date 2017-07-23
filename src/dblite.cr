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
db.write do |w|
  tree = BTree.create(w)

  5.times do |i|
    k = BTree.make_key i
    obj = "Hello #{i}!"
    data = Data.create(w, obj)
    tree.insert(w, k, data.pos)
  end
end
t=Time.now-s

# db.write do |writter|
#   writter.alloc('E')
# end

# db.write do |writter|
#   writter.alloc('E')
#   writter.alloc('E')
#   writter.del(1u32)
#   writter.alloc('E')
# end

db.debug
p t
# p db
