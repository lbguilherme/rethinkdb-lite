require "./database_file"

require "msgpack"
require "openssl"


struct StaticArray(T, N)
  include Comparable(StaticArray(T, N))
  def <=>(other : StaticArray(T, N))
    0.upto(size - 1) do |i|
      n = to_unsafe[i] <=> other.to_unsafe[i]
      return n if n != 0
    end
    0
  end
end

struct BTree
  alias Key = StaticArray(UInt8, 32)

  def initialize(@root : UInt32)
  end

  def self.create(w : DatabaseFile::Writter)
    new(w.alloc('L').pos)
  end

  @@digester = OpenSSL::Digest.new("SHA256")
  def self.make_key(obj)
    packer = MessagePack::Packer.new
    packer.write(obj)

    @@digester.reset
    @@digester.update(packer.to_slice)

    slice = @@digester.digest
    Key.new do |i|
      i < slice.size ? slice[i] : 0u8
    end
  end

  def list_offset
    x = DatabaseFile::BTreeLeafPage.new
    pointerof(x.@list).address - pointerof(x).address
  end

  def insert(w : DatabaseFile::Writter, key : Key, value : UInt32)
    page = w.get(@root)
    insert_at_page(w, page, key, value)
  end

  private def insert_at_page(w : DatabaseFile::Writter, page : DatabaseFile::PageRef, key : Key, value : UInt32)
    if page.type == 'L'
      leaf = page.as_leaf
      max_count = {255, ((page.size - list_offset) / (sizeof(Key) + 4)).to_i}.min

      arr = [] of {Key, UInt32}
      leaf.value.count.times do |i|
        arr << leaf.value.list.to_unsafe[i]
      end
      arr << {key, value}
      arr.sort_by! {|e| e[0] }

      if arr.size > max_count
        new_page = w.alloc('L')
        new_leaf = new_page.as_leaf

        arr.each_with_index do |e, i|
          if i < max_count/2
            leaf.value.list.to_unsafe[i] = e
          else
            new_leaf.value.list.to_unsafe[i - max_count/2] = e
          end
        end

        leaf.value.count = (max_count/2).to_u8
        new_leaf.value.count = (arr.size - max_count/2).to_u8

        w.put(page)
        w.put(new_page)
      else
        arr.each_with_index do |e, i|
          leaf.value.list.to_unsafe[i] = e
        end

        p arr.size

        leaf.value.count = leaf.value.count + 1
        w.put(page)
      end
    else
      # node
    end
  end

  def query(r : DatabaseFile::Reader, key : Key)
  end

  def debug
# digraph g {
# node [shape = record,height=.1];
# node0[label = "<f0> |10|<f1> |20|<f2> |30|<f3>"];
# node1[label = "<f0> |1|<f1> |2|<f2>"];
# "node0":f0 -> "node1"
# node2[label = "<f0> |11|<f1> |12|<f2>"];
# "node0":f1 -> "node2"
# node3[label = "<f0> |21|<f1> |22|<f2>"];
# "node0":f2 -> "node3"
# node4[label = "<f0> |31|<f1> |32|<f2>"];
# "node0":f3 -> "node4"
# }


  end
end