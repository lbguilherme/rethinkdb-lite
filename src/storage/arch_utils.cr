

lib LibC
  FALLOC_FL_KEEP_SIZE = 1
  FALLOC_FL_PUNCH_HOLE = 2
  fun fsync(fd : Int32) : Int32
  fun fallocate(fd : Int32, mode : Int32, offset : OffT, len : OffT) : Int32
  fun ftruncate(fd : Int32, len : OffT) : Int32
end

module ArchUtils
  def self.grow_sparse_file(file : File, size : UInt64)
    if LibC.fallocate(file.@fd, 0, 0, size) != 0
      raise Errno.new("fallocate")
    end
  end

  def self.truncate_file(file : File, size : UInt64)
    if LibC.ftruncate(file.@fd, size) != 0
      raise Errno.new("ftruncate")
    end
  end

  def self.sync_file(file : File)
    if LibC.fsync(file.@fd) != 0
      raise Errno.new("fsync")
    end
  end

  def self.punch_hole_in_file(file : File, offset : UInt64, len : UInt64)
    if LibC.fallocate(file.@fd, LibC::FALLOC_FL_PUNCH_HOLE | LibC::FALLOC_FL_KEEP_SIZE, offset, len) != 0
      raise Errno.new("fallocate")
    end
  end
end
