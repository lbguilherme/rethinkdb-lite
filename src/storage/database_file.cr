
# Header:
# 8 bytes magic  DBLITE01
# 2 bytes page size
# 4 bytes address first free page

require "./arch_utils"

class DatabaseFile
  def initialize(@file : File, @wal_file : File)
    @file.sync = true
    @file.rewind
    @wal_file.sync = true
    @wal_file.rewind

    @page_size = 1024u16
    @page_count = 1u32
    @real_page_count = 1u32
    @first_free_page = 0u32
    @wal = Array(Hash(UInt32, UInt32)).new
    @next_wal = Hash(UInt32, UInt32).new
    @wal_count = 1u32
    @wal_skip = 0u32

    header = read_file_page(0u32).as_header.value

    @page_size = header.page_size
    @file.seek(0, IO::Seek::End)
    @page_count = (@file.pos / @page_size).to_u32
    @real_page_count = @page_count
    @first_free_page = header.first_free_page

    skip = read_wal_page(0u32).as_wal.value.skip_page_count
    @wal_file.seek(0, IO::Seek::End)
    @wal_count = (@wal_file.pos / @page_size).to_u32
    last_commit_pos = 0u32
    next_page_count = @page_count
    ((skip+1)...@wal_count).each do |wpos|
      page = read_wal_page(wpos)
      if page.type == 'C'
        @wal << @next_wal
        @next_wal = Hash(UInt32, UInt32).new
        last_commit_pos = wpos
        @page_count = next_page_count
      else
        next_page_count = {next_page_count, page.pos + 1}.max
        @next_wal[page.pos] = wpos
      end
    end
    @wal_count = last_commit_pos + 1
    @next_wal = Hash(UInt32, UInt32).new
  end

  def close
    @file.close
    @wal_file.close
  end

  struct Writter
    def initialize(@db : DatabaseFile)
    end

    def alloc(chr : Char)
      @db.allocate_page(chr)
    end

    def put(page : PageRef)
      @db.write_page(page)
    end

    def get(pos : UInt32)
      @db.read_page(pos)
    end

    def del(pos : UInt32)
      @db.delete_page(pos)
    end
  end

  struct Reader
    def initialize(@db : DatabaseFile, @version : UInt32)
    end

    def get(pos : UInt32)
      @db.read_page_upto_version(pos, @version)
    end
  end

  def write
    writter = Writter.new(self)
    begin
      yield writter
    rescue ex
      rollback
      raise ex
    else
      commit
    end
  end

  def read
    current_version = @wal.size.to_u32 + @wal_skip
    reader = Reader.new(self, current_version)
    yield reader
  end

  def debug
    puts "\nMain:"
    @page_count.times do |pos|
      read_page(pos).debug
    end
    puts "\nWAL:"
    @wal_count.times do |pos|
      read_wal_page(pos).debug
    end
  end

  def write_page(page)
    @wal_file.seek(0, IO::Seek::End)
    @wal_file.write(Bytes.new(page.pointer, @page_size))
    @next_wal[page.pos] = @wal_count
    @wal_count += 1
  end

  def commit
    ptr = Pointer(UInt8).malloc(@page_size)
    page = ptr.as(CommitPage*)
    page.value.type = 'C'.ord.to_u8

    @wal_file.seek(0, IO::Seek::End)
    @wal_file.write(Bytes.new(ptr, @page_size))
    @wal_count += 1

    @wal << @next_wal
    @next_wal = Hash(UInt32, UInt32).new
  end

  def rollback
    @wal_count -= @next_wal.size
    @next_wal = Hash(UInt32, UInt32).new
  end

  def delete_page(pos : UInt32)
    if pos > @page_count
      raise Error.new("Writting page #{pos} out of bounds")
    end

    header_page_ref = read_page(0u32)

    page_ref = PageRef.new(Pointer(UInt8).malloc(@page_size))
    page = page_ref.as_any
    page.value.type = 'F'.ord.to_u8
    page.value.pos = pos
    page_ref.as_free.value.next_free_page = @first_free_page
    @first_free_page = header_page_ref.as_header.value.first_free_page = pos

    write_page(page_ref)
    write_page(header_page_ref)
  end

  def allocate_page(chr : Char)
    if @first_free_page == 0
      page_ref = PageRef.new(Pointer(UInt8).malloc(@page_size))
      page = page_ref.as_any
      page.value.type = chr.ord.to_u8
      page.value.pos = @page_count
      write_page(page_ref)
      @page_count += 1
      page_ref
    else
      free_page_ref = read_page(@first_free_page)
      header_page_ref = read_page(0u32)
      @first_free_page = header_page_ref.as_header.value.first_free_page = free_page_ref.as_free.value.next_free_page
      free_page_ref.as_any.value.type = chr.ord.to_u8
      write_page(header_page_ref)
      write_page(free_page_ref)
      free_page_ref
    end
  end

  def todo
    raise Error.new("TODO")
  end

  def read_page(pos : UInt32)
    if wpos = @next_wal[pos]?
      return read_wal_page(wpos)
    end
    @wal.reverse_each do |table|
      if wpos = table[pos]?
        return read_wal_page(wpos)
      end
    end

    read_file_page(pos)
  end

  def read_page_upto_version(pos : UInt32, version : UInt32)
    current_version = @wal.size + @wal_skip
    skip = current_version - version
    @wal.reverse_each.skip(skip).each do |table|
      if wpos = table[pos]?
        return read_wal_page(wpos)
      end
    end

    read_file_page(pos)
  end

  def read_file_page(pos : UInt32)
    if pos > @real_page_count
      raise Error.new("Reading page #{pos} out of bounds")
    end
    slice = Bytes.new(@page_size)
    @file.pos = @page_size * pos
    @file.read(slice)
    PageRef.new(slice.pointer(@page_size))
  end

  def read_wal_page(pos : UInt32)
    if pos > @wal_count
      raise Error.new("Reading page #{pos} out of bounds")
    end
    slice = Bytes.new(@page_size)
    @wal_file.pos = @page_size * pos
    @wal_file.read(slice)
    PageRef.new(slice.pointer(@page_size))
  end

  def self.open(path : String)
    file = File.new(path, "r+")
    walfile = File.new(path + ".wal", "r+")
    return new(file, walfile)
  end

  def self.create(path : String, options : CreateOptions = CreateOptions.new)
    if File.exists?(path)
      raise Error.new("File '#{path}' already exists")
    end

    file = File.new(path, "w+")
    ArchUtils.grow_sparse_file(file, 1u64 * options.page_size)

    header = HeaderPage.new
    header.type = 'H'.ord.to_u8
    header.page_size = options.page_size
    file.write Bytes.new(pointerof(header).as UInt8*, sizeof(HeaderPage))

    wal_file = File.new(path + ".wal", "w+")
    ArchUtils.grow_sparse_file(wal_file, 1u64 * options.page_size)

    wal_start = WalStartPage.new
    wal_start.type = 'W'.ord.to_u8
    wal_start.skip_page_count = 1u32
    wal_file.write Bytes.new(pointerof(wal_start).as UInt8*, sizeof(WalStartPage))

    return new(file, wal_file)
  end

  class Error < Exception
  end

  struct PageRef
    property pointer

    def initialize(@pointer : Pointer(UInt8))
    end

    private def ensure_type(chr)
      if type != chr
        raise Error.new("Expected page at #{pos} to be of type #{chr} found type #{type}")
      end
    end

    def pos
      @pointer.as(AnyPage*).value.pos
    end

    def type
      @pointer.as(AnyPage*).value.type.chr
    end

    def debug
      print "% 8d " % pos
      case type
      when 'H'
        print "% 10s | free=%d" % ["Header", as_header.value.first_free_page]
      when 'E'
        print "% 10s | " % "Empty"
      when 'F'
        print "% 10s | next=%d" % ["Free", as_free.value.next_free_page]
      when 'W'
        print "% 10s | skip=%d" % ["WAL", as_wal.value.skip_page_count]
      when 'C'
        print "% 10s | " % "Commit"
      else
        print "% 10s | " % "Unknown"
      end

      puts ""
    end

    def as_any
      return @pointer.as(AnyPage*)
    end

    def as_header
      ensure_type 'H'
      return @pointer.as(HeaderPage*)
    end

    def as_empty
      ensure_type 'E'
      return @pointer.as(EmptyPage*)
    end

    def as_free
      ensure_type 'F'
      return @pointer.as(FreePage*)
    end

    def as_commit
      ensure_type 'C'
      return @pointer.as(CommitPage*)
    end

    def as_wal
      ensure_type 'W'
      return @pointer.as(WalStartPage*)
    end
  end

  struct CreateOptions
    property page_size = 4096u16
  end

  abstract struct Page
    property type = 0u8
    property version = 0u8
    property reserved1 = 0u16
    property pos = 0u32
  end

  struct AnyPage < Page
  end

  struct HeaderPage < Page
    property page_size = 0u16
    property reserved2 = 0u16
    property first_free_page = 0u32
  end

  struct EmptyPage < Page
  end

  struct CommitPage < Page
  end

  struct FreePage < Page
    property next_free_page = 0u32
  end

  struct WalStartPage < Page
    property skip_page_count = 0u32
  end
end

