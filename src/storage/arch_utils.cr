

lib LibC
  fun fsync(fd : Int32) : Int32
  fun fallocate(fd : Int32, mode : Int32, offset : OffT, len : OffT) : Int32
end

module ArchUtils
  def self.grow_sparse_file(file : File, size : UInt64)
    if LibC.fallocate(file.@fd, 0, 0, size) != 0
      raise Errno.new("fallocate")
    end
  end

  def self.sync_file(file : File)
    if LibC.fsync(file.@fd) != 0
      raise Errno.new("fsync")
    end
  end
end
