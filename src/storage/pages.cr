module Storage
  class Error < Exception
  end

  struct PageRef
    def initialize(@slice : Slice(UInt8))
    end

    private def ensure_type(chr)
      if type != chr
        raise Error.new("Expected page at #{pos} to be of type #{chr} found type #{type}")
      end
    end

    def pointer
      @slice.to_unsafe
    end

    def size
      @slice.size
    end

    def pos
      pointer.as(AnyPage*).value.pos
    end

    def type
      pointer.as(AnyPage*).value.type.chr
    end

    def debug
      return if type == 'D'
      print "% 5d " % pos
      case type
      when 'H'
        print "% 14s | free=%d table=%d" % ["Header", as_header.value.first_free_page, as_header.value.table_btree_pos]
      when 'E'
        print "% 14s | %s" % ["Empty", String.new(pointer.as(UInt8*) + 200)] # debug
      when 'F'
        print "% 14s | next=%d" % ["Free", as_free.value.next_free_page]
      when 'W'
        print "% 14s | skip=%d" % ["WAL", as_wal.value.skip_page_count]
      when 'C'
        print "% 14s | " % "Commit"
      when 'B'
        print "% 14s | %d pointers" % ["Table Node", as_node.value.count]
      when 'b'
        print "% 14s | %d elements" % ["Table Leaf", as_leaf.value.count]
      when 'D'
        print "% 14s | %d bytes -- succ=%d" % ["Data", as_data.value.size, as_data.value.succ]
      else
        print "% 14s | " % "Unknown"
      end

      puts ""
    end

    def as_any
      return pointer.as(AnyPage*)
    end

    def as_header
      ensure_type 'H'
      return pointer.as(HeaderPage*)
    end

    def as_empty
      ensure_type 'E'
      return pointer.as(EmptyPage*)
    end

    def as_free
      ensure_type 'F'
      return pointer.as(FreePage*)
    end

    def as_commit
      ensure_type 'C'
      return pointer.as(CommitPage*)
    end

    def as_wal
      ensure_type 'W'
      return pointer.as(WalStartPage*)
    end

    def as_node
      ensure_type 'B'
      return pointer.as(BTreeNodePage*)
    end

    def as_leaf
      ensure_type 'b'
      return pointer.as(BTreeLeafPage*)
    end

    def as_data
      ensure_type 'D'
      return pointer.as(DataPage*)
    end
  end

  @[Packed]
  abstract struct Page
    property type = 0u8
    property version = 0u8
    property pos = 0u32
  end

  @[Packed]
  struct AnyPage < Page
  end

  @[Packed]
  struct HeaderPage < Page
    property page_size = 0u16
    property first_free_page = 0u32
    property table_btree_pos = 0u32
  end

  @[Packed]
  struct EmptyPage < Page
  end

  @[Packed]
  struct CommitPage < Page
  end

  @[Packed]
  struct FreePage < Page
    property next_free_page = 0u32
  end

  @[Packed]
  struct WalStartPage < Page
    property skip_page_count = 0u32
  end

  @[Packed]
  struct BTreeNodePage < Page
    property count = 0u8
    property list = StaticArray({BTree::Key, UInt32}, 1).new({BTree::Key.new(0u8), 0u32})
  end

  @[Packed]
  struct BTreeLeafPage < Page
    property prev = 0u32
    property succ = 0u32
    property count = 0u8
    property list = StaticArray({BTree::Key, UInt32}, 1).new({BTree::Key.new(0u8), 0u32})
  end

  @[Packed]
  struct DataPage < Page
    property size = 0u32
    property succ = 0u32
    property data = 0u8
  end
end
