@[Link("rocksdb")]
lib LibRocksDb
  fun free = rocksdb_free(ptr : Void*) : Void

  struct Options
    dummy : UInt8
  end

  fun options_create = rocksdb_options_create : Options*
  fun options_destroy = rocksdb_options_destroy(options : Options*) : Void
  fun options_set_create_if_missing = rocksdb_options_set_create_if_missing(options : Options*, value : UInt8) : Void
  fun options_set_paranoid_checks = rocksdb_options_set_paranoid_checks(options : Options*, value : UInt8) : Void

  struct Db
    dummy : UInt8
  end

  fun open = rocksdb_open(options : Options*, name : UInt8*, errptr : UInt8**) : Db*
  fun close = rocksdb_close(db : Db*) : Void

  struct OptimisticTransactionDb
    dummy : UInt8
  end

  fun optimistictransactiondb_open = rocksdb_optimistictransactiondb_open(options : Options*, name : UInt8*, errptr : UInt8**) : OptimisticTransactionDb*
  fun optimistictransactiondb_close = rocksdb_optimistictransactiondb_close(optimistic_transaction_db : OptimisticTransactionDb*) : Void
  fun optimistictransactiondb_get_base_db = rocksdb_optimistictransactiondb_get_base_db(optimistic_transaction_db : OptimisticTransactionDb*) : Db*
  fun optimistictransactiondb_close_base_db = rocksdb_optimistictransactiondb_close_base_db(db : Db*) : Void

  struct OptimisticTransactionOptions
    dummy : UInt8
  end

  fun optimistictransaction_options_create = rocksdb_optimistictransaction_options_create : OptimisticTransactionOptions*
  fun optimistictransaction_options_destroy = rocksdb_optimistictransaction_options_destroy(optimistic_transaction_options : OptimisticTransactionOptions*) : Void
  fun optimistictransaction_options_set_set_snapshot = rocksdb_optimistictransaction_options_set_set_snapshot(optimistic_transaction_options : OptimisticTransactionOptions*, value : UInt8) : Void

  struct Transaction
    dummy : UInt8
  end

  fun optimistictransaction_begin = rocksdb_optimistictransaction_begin(optimistic_transaction_db : OptimisticTransactionDb*, write_options : WriteOptions*, otxn_options : OptimisticTransactionOptions*, old_txn : Transaction*) : Transaction*
  fun transaction_commit = rocksdb_transaction_commit(txn : Transaction*, errptr : UInt8**)
  fun transaction_rollback = rocksdb_transaction_rollback(txn : Transaction*, errptr : UInt8**)
  fun transaction_set_savepoint = rocksdb_transaction_set_savepoint(txn : Transaction*)
  fun transaction_rollback_to_savepoint = rocksdb_transaction_rollback_to_savepoint(txn : Transaction*, errptr : UInt8**)
  fun transaction_destroy = rocksdb_transaction_destroy(txn : Transaction*)
  fun transaction_get = rocksdb_transaction_get(txn : Transaction*, read_options : ReadOptions*, key : UInt8*, keylen : LibC::SizeT, vallen : LibC::SizeT*, errptr : UInt8**) : UInt8*
  fun transaction_get_for_update = rocksdb_transaction_get_for_update(txn : Transaction*, read_options : ReadOptions*, key : UInt8*, keylen : LibC::SizeT, vallen : LibC::SizeT*, exclusive : UInt8, errptr : UInt8**) : UInt8*
  fun transaction_put = rocksdb_transaction_put(txn : Transaction*, key : UInt8*, keylen : LibC::SizeT, val : UInt8*, vallen : LibC::SizeT, errptr : UInt8**) : Void

  struct ReadOptions
    dummy : UInt8
  end

  fun readoptions_create = rocksdb_readoptions_create : ReadOptions*
  fun readoptions_destroy = rocksdb_readoptions_destroy(read_options : ReadOptions*) : Void
  fun readoptions_set_iterate_upper_bound = rocksdb_readoptions_set_iterate_upper_bound(read_options : ReadOptions*, key : UInt8*, keylen : LibC::SizeT)
  fun readoptions_set_iterate_lower_bound = rocksdb_readoptions_set_iterate_lower_bound(read_options : ReadOptions*, key : UInt8*, keylen : LibC::SizeT)

  struct WriteOptions
    dummy : UInt8
  end

  fun writeoptions_create = rocksdb_writeoptions_create : WriteOptions*
  fun writeoptions_destroy = rocksdb_writeoptions_destroy(write_options : WriteOptions*) : Void

  fun get = rocksdb_get(db : Db*, read_options : ReadOptions*, key : UInt8*, keylen : LibC::SizeT, vallen : LibC::SizeT*, errptr : UInt8**) : UInt8*
  fun put = rocksdb_put(db : Db*, write_options : WriteOptions*, key : UInt8*, keylen : LibC::SizeT, val : UInt8*, vallen : LibC::SizeT, errptr : UInt8**) : Void

  struct Iterator
    dummy : UInt8
  end

  fun create_iterator = rocksdb_create_iterator(db : Db*, read_options : ReadOptions*) : Iterator*
  fun iter_destroy = rocksdb_iter_destroy(iter : Iterator*)
  fun iter_valid = rocksdb_iter_valid(iter : Iterator*) : UInt8
  fun iter_seek_to_first = rocksdb_iter_seek_to_first(iter : Iterator*) : Void
  fun iter_seek_to_last = rocksdb_iter_seek_to_last(iter : Iterator*) : Void
  fun iter_seek = rocksdb_iter_seek(iter : Iterator*, key : UInt8*, keylen : LibC::SizeT) : Void
  fun iter_seek_for_prev = rocksdb_iter_seek_for_prev(iter : Iterator*, key : UInt8*, keylen : LibC::SizeT) : Void
  fun iter_next = rocksdb_iter_next(iter : Iterator*) : Void
  fun iter_prev = rocksdb_iter_prev(iter : Iterator*) : Void
  fun iter_key = rocksdb_iter_key(iter : Iterator*, keylen : LibC::SizeT*) : UInt8*
  fun iter_value = rocksdb_iter_value(iter : Iterator*, vallen : LibC::SizeT*) : UInt8*
  fun iter_get_error = rocksdb_iter_get_error(iter : Iterator*, errptr : UInt8**) : Void
end

private def err_check
  err = Pointer(UInt8).null
  result = yield pointerof(err)
  unless err.null?
    str = String.new(err)
    puts str
    RocksDb.free(err)
    raise RocksDb::Error.new(str)
  end
  result
end

module RocksDb
  def self.free(ptr : UInt8*)
    LibRocksDb.free(ptr)
  end

  class Error < Exception
  end

  class ClosedDatabase < Error
  end

  class Options
    @value : LibRocksDb::Options*

    def to_unsafe
      @value
    end

    def initialize
      @value = LibRocksDb.options_create
    end

    def finalize
      LibRocksDb.options_destroy(self)
    end

    def create_if_missing=(value : Bool)
      LibRocksDb.options_set_create_if_missing(self, value ? 1 : 0)
    end

    def paranoid_checks=(value : Bool)
      LibRocksDb.options_set_paranoid_checks(self, value ? 1 : 0)
    end
  end

  class Database
    @value : LibRocksDb::Db*

    def to_unsafe
      @value
    end

    def initialize(@value : LibRocksDb::Db*)
      @default_read_options = ReadOptions.new
      @default_write_options = WriteOptions.new
    end

    def finalize
      close unless @value.null?
    end

    def close
      LibRocksDb.close(self)
      @value = Pointer(LibRocksDb::Db).null
    end

    def self.open(options : Options, path : String)
      new(err_check do |err|
        LibRocksDb.open(options, path, err)
      end)
    end

    def get(key : Bytes, read_options : ReadOptions = @default_read_options) : Bytes?
      raise ClosedDatabase.new if @value.null?
      len = uninitialized LibC::SizeT
      ptr = err_check do |err|
        LibRocksDb.get(self, read_options, key, key.size, pointerof(len), err)
      end
      ptr.null? ? nil : Bytes.new(ptr, len)
    end

    def put(key : Bytes, value : Bytes, write_options : WriteOptions = @default_write_options)
      raise ClosedDatabase.new if @value.null?
      err_check do |err|
        LibRocksDb.put(self, write_options, key, key.size, value, value.size, err)
      end
    end

    def iterator(read_options : ReadOptions = @default_read_options)
      raise ClosedDatabase.new if @value.null?
      Iterator.new(LibRocksDb.create_iterator(self, read_options))
    end
  end

  class OptimisticTransactionDatabase < Database
    def self.open(options : Options, path : String) : OptimisticTransactionDatabase
      optimistic_transaction_db = err_check do |err|
        LibRocksDb.optimistictransactiondb_open(options, path, err)
      end
      new(LibRocksDb.optimistictransactiondb_get_base_db(optimistic_transaction_db), optimistic_transaction_db)
    end

    def initialize(value, @optimistic_transaction_db : LibRocksDb::OptimisticTransactionDb*)
      super(value)
      @default_optimistic_transaction_options = OptimisticTransactionOptions.new
    end

    def close
      LibRocksDb.optimistictransactiondb_close_base_db(@value)
      LibRocksDb.optimistictransactiondb_close(@optimistic_transaction_db)
      @value = Pointer(LibRocksDb::Db).null
      @optimistic_transaction_db = Pointer(LibRocksDb::OptimisticTransactionDb).null
    end

    def begin_transaction(write_options : WriteOptions = @default_write_options, optimistic_transaction_options : OptimisticTransactionOptions = @default_optimistic_transaction_options)
      raise ClosedDatabase.new if @value.null?
      OptimisticTransaction.new(
        LibRocksDb.optimistictransaction_begin(@optimistic_transaction_db, write_options, optimistic_transaction_options, nil),
        @default_read_options,
        @default_write_options,
        @default_optimistic_transaction_options,
        self
      )
    end

    def begin_transaction(old : OptimisticTransaction, write_options : WriteOptions = @default_write_options, optimistic_transaction_options : OptimisticTransactionOptions = @default_optimistic_transaction_options)
      raise ClosedDatabase.new if @value.null?
      LibRocksDb.optimistictransaction_begin(@optimistic_transaction_db, write_options, optimistic_transaction_options, old)
    end
  end

  class Transaction
    @value : LibRocksDb::Transaction*
    @default_read_options : ReadOptions
    @default_write_options : WriteOptions

    def to_unsafe
      @value
    end

    def initialize(@value : LibRocksDb::Transaction*, @default_read_options : ReadOptions, @default_write_options : WriteOptions)
    end

    def finalize
      LibRocksDb.transaction_destroy(self)
    end

    def commit
      err_check { |err| LibRocksDb.transaction_commit(self, err) }
    end

    def rollback
      err_check { |err| LibRocksDb.transaction_rollback(self, err) }
    end

    def set_savepoint
      LibRocksDb.rocksdb_transaction_set_savepoint(self)
    end

    def rollback_to_savepoint
      err_check { |err| LibRocksDb.transaction_rollback_to_savepoint(self, err) }
    end

    def get(key : Bytes, read_options : ReadOptions = @default_read_options) : Bytes?
      len = uninitialized LibC::SizeT
      ptr = err_check do |err|
        LibRocksDb.transaction_get_for_update(self, read_options, key, key.size, pointerof(len), 1, err)
      end
      ptr.null? ? nil : Bytes.new(ptr, len)
    end

    def put(key : Bytes, value : Bytes)
      err_check do |err|
        LibRocksDb.transaction_put(self, key, key.size, value, value.size, err)
      end
      nil
    end
  end

  class OptimisticTransaction < Transaction
    @default_optimistic_transaction_options : OptimisticTransactionOptions
    @optimistic_transaction_db : OptimisticTransactionDatabase

    def initialize(value, default_read_options, default_write_options, @default_optimistic_transaction_options : OptimisticTransactionOptions, @optimistic_transaction_db : OptimisticTransactionDatabase)
      super(value, default_read_options, default_write_options)
    end

    def begin(write_options : WriteOptions = @default_write_options, optimistic_transaction_options : OptimisticTransactionOptions = @default_optimistic_transaction_options)
      @optimistic_transaction_db.begin_transaction(self, write_options, optimistic_transaction_options)
    end
  end

  class ReadOptions
    @value : LibRocksDb::ReadOptions*

    def to_unsafe
      @value
    end

    def initialize
      @value = LibRocksDb.readoptions_create
    end

    def finalize
      LibRocksDb.readoptions_destroy(self)
    end

    def iterate_upper_bound=(key : Bytes)
      LibRocksDb.readoptions_set_iterate_upper_bound(self, key, key.size)
    end

    def iterate_lower_bound=(key : Bytes)
      LibRocksDb.readoptions_set_iterate_lower_bound(self, key, key.size)
    end
  end

  class WriteOptions
    @value : LibRocksDb::WriteOptions*

    def to_unsafe
      @value
    end

    def initialize
      @value = LibRocksDb.writeoptions_create
    end

    def finalize
      LibRocksDb.writeoptions_destroy(self)
    end
  end

  class OptimisticTransactionOptions
    @value : LibRocksDb::OptimisticTransactionOptions*

    def to_unsafe
      @value
    end

    def initialize
      @value = LibRocksDb.optimistictransaction_options_create
    end

    def finalize
      LibRocksDb.optimistictransaction_options_destroy(self)
    end

    def set_snapshot=(value : Bool)
      LibRocksDb.optimistictransaction_options_set_set_snapshot(self, value ? 1 : 0)
    end
  end

  class Iterator
    @value : LibRocksDb::Iterator*

    def to_unsafe
      @value
    end

    def initialize(@value : LibRocksDb::Iterator*)
    end

    def finalize
      LibRocksDb.iter_destroy(self)
    end

    def valid?
      result = LibRocksDb.iter_valid(self) != 0
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
      result
    end

    def seek_to_first
      LibRocksDb.iter_seek_to_first(self)
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
    end

    def seek_to_last
      LibRocksDb.iter_seek_to_last(self)
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
    end

    def seek(key : Bytes)
      LibRocksDb.iter_seek(self, key, key.size)
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
    end

    def seek_for_prev(key : Bytes)
      LibRocksDb.iter_seek_for_prev(self, key, key.size)
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
    end

    def next
      LibRocksDb.iter_next(self)
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
    end

    def prev
      LibRocksDb.iter_prev(self)
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
    end

    def key
      len = LibC::SizeT.new(0)
      ptr = LibRocksDb.iter_key(self, pointerof(len))
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
      Bytes.new(ptr, len)
    end

    def value
      len = LibC::SizeT.new(0)
      ptr = LibRocksDb.iter_value(self, pointerof(len))
      err_check { |err| LibRocksDb.iter_get_error(self, err) }
      Bytes.new(ptr, len)
    end
  end
end
