require "./database_file"
require "./btree"

class Table
  def self.create(w : DatabaseFile::Writter)
    new BTree.create(w).pos
  end

  def pos
    @btree.pos
  end

  def initialize(pos : UInt32)
    @btree = BTree.new(pos)
  end

  def insert(w : DatabaseFile::Writter, obj)
    k = BTree.make_key obj["id"]
    data = Data.create(w, obj)
    @btree.insert(w, k, data.pos)
  end

  def get(r : DatabaseFile::Reader, pkey)
    k = BTree.make_key pkey
    pos = @btree.query(r, k)
    if pos == 0u32
      nil
    else
      Data.new(r.get(pos)).read(r)
    end
  end
end
