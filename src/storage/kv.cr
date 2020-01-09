require "uuid"
require "file_utils"
require "rocksdb"
require "../reql/helpers/table_writter"
require "../reql/executor/func"
require "../reql/executor/reql_func"
require "../reql/terms/var"

module Storage
  class KeyValueStore
    PREFIX_SYSTEM_INFO      = 0u8
    PREFIX_DATABASES        = 1u8
    PREFIX_TABLES           = 2u8
    PREFIX_TABLE_DATA       = 3u8
    TABLE_PREFIX_INDICES    = 0u8
    TABLE_PREFIX_INDEX_DATA = 1u8

    # Minimal durability: data it stored in memory only and flushed to disk at some later point.
    # A process crash might cause data loss. A graceful server close (calling .close()) won't lose data.
    # Note: The data might be lost, but it won't be corrupted. This is the fastest option.
    MINIMAL_DURABILITY = RocksDB::WriteOptions.new
    MINIMAL_DURABILITY.disable_wal = true
    MINIMAL_DURABILITY.sync = false

    # Soft durability: data is sent to the operating system memory and will be synced to disk later.
    # Only a kernel panic or hardware failure might cause data loss. Crashing the process won't lose any data.
    SOFT_DURABILITY = RocksDB::WriteOptions.new
    SOFT_DURABILITY.disable_wal = false
    SOFT_DURABILITY.sync = false

    # Hard durability: data is written on disk always. This is the default and this is paranoic. No data will be lost, ever.
    HARD_DURABILITY = RocksDB::WriteOptions.new
    HARD_DURABILITY.disable_wal = false
    HARD_DURABILITY.sync = true

    def self.key_for_system_info
      Bytes[PREFIX_SYSTEM_INFO]
    end

    def self.key_for_database(id : UUID)
      io = IO::Memory.new(17)
      io.write_bytes(PREFIX_DATABASES)
      io.write(id.bytes.to_slice)
      io.to_slice
    end

    def self.key_for_table(id : UUID)
      io = IO::Memory.new(17)
      io.write_bytes(PREFIX_TABLES)
      io.write(id.bytes.to_slice)
      io.to_slice
    end

    def self.key_for_table_index(index_id : UUID)
      io = IO::Memory.new
      io.write_bytes(TABLE_PREFIX_INDICES)
      io.write(index_id.bytes.to_slice)
      io.to_slice
    end

    def self.key_for_table_index_start
      io = IO::Memory.new
      io.write_bytes(TABLE_PREFIX_INDICES)
      io.to_slice
    end

    def self.key_for_table_index_end
      io = IO::Memory.new
      io.write_bytes(TABLE_PREFIX_INDICES + 1u8)
      io.to_slice
    end

    def self.key_for_table_index_entry(index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
      io = IO::Memory.new
      io.write_bytes(TABLE_PREFIX_INDEX_DATA)
      io.write(index_id.bytes.to_slice)
      io.write_bytes(0u8)
      io.write(index_value)
      io.write_bytes(0u8)
      io.write_bytes(counter, IO::ByteFormat::LittleEndian)
      io.write(primary_key)
      io.write_bytes(primary_key.size.to_u32, IO::ByteFormat::LittleEndian)
      io.to_slice
    end

    def self.key_for_table_index_entry_start(index_id : UUID, index_value : Bytes)
      io = IO::Memory.new
      io.write_bytes(TABLE_PREFIX_INDEX_DATA)
      io.write(index_id.bytes.to_slice)
      io.write_bytes(0u8)
      io.write(index_value)
      io.write_bytes(0u8)
      io.to_slice
    end

    def self.key_for_table_index_entry_end(index_id : UUID, index_value : Bytes)
      io = IO::Memory.new
      io.write_bytes(TABLE_PREFIX_INDEX_DATA)
      io.write(index_id.bytes.to_slice)
      io.write_bytes(0u8)
      io.write(index_value)
      io.write_bytes(1u8)
      io.to_slice
    end

    def self.decompose_index_entry_key(index_entry_key : Bytes)
      io = IO::Memory.new(index_entry_key, false)
      io.seek(index_entry_key.size - 4)

      primary_key = Bytes.new(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
      io.seek(index_entry_key.size - 4 - primary_key.size)
      io.read_fully(primary_key)

      index_value = Bytes.new(index_entry_key.size - 1 - 16 - 1 - 1 - primary_key.size - 4 - 4)
      io.seek(1 + 16 + 1)
      io.read_fully(index_value)

      return {index_value, primary_key}
    end

    property system_info

    {% if flag?(:preview_mt) %}
      @rocksdb : RocksDB::TransactionDatabase
    {% else %}
      @rocksdb : RocksDB::OptimisticTransactionDatabase
    {% end %}

    def initialize(path)
      @options = RocksDB::Options.new
      @options.create_if_missing = true
      @options.paranoid_checks = true

      {% if flag?(:preview_mt) %}
        @options.enable_pipelined_write = true
        @options.increase_parallelism(16)
        @options.max_background_jobs = 4
      {% end %}

      FileUtils.mkdir_p path

      if File.exists? Path.new(path, "CURRENT")
        families = RocksDB::Database.list_column_families(path, @options).map { |name| {name, @options} }.to_h
      else
        families = {"default" => @options}
      end

      @rocksdb = {% if flag?(:preview_mt) %}
                   RocksDB::TransactionDatabase.open(path, @options, families)
                 {% else %}
                   RocksDB::OptimisticTransactionDatabase.open(path, @options, families)
                 {% end %}

      system_info_bytes = @rocksdb.get(KeyValueStore.key_for_system_info)
      @system_info = system_info_bytes.nil? ? SystemInfo.new : SystemInfo.load(system_info_bytes)

      migrate
    end

    @table_data_family_cache = {} of UUID => RocksDB::ColumnFamilyHandle

    def table_data_family(id : UUID)
      handle = @table_data_family_cache[id]?
      return handle if handle
      name = "table.#{id}.data"
      handle = @rocksdb.family_handle?(name)
      handle = @rocksdb.create_column_family(name, @options) unless handle
      @table_data_family_cache[id] = handle
    end

    @table_metadata_family_cache = {} of UUID => RocksDB::ColumnFamilyHandle

    def table_metadata_family(id : UUID)
      handle = @table_metadata_family_cache[id]?
      return handle if handle
      name = "table.#{id}.metadata"
      handle = @rocksdb.family_handle?(name)
      handle = @rocksdb.create_column_family(name, @options) unless handle
      @table_metadata_family_cache[id] = handle
    end

    def close
      @rocksdb.close
    end

    private def get_write_options(durability : ReQL::Durability)
      case durability
      when ReQL::Durability::Soft
        SOFT_DURABILITY
      when ReQL::Durability::Hard
        HARD_DURABILITY
      when ReQL::Durability::Minimal
        MINIMAL_DURABILITY
      else
        raise "BUG: unknown durability"
      end
    end

    def get_db(id : UUID)
      bytes = @rocksdb.get(KeyValueStore.key_for_database(id))
      if bytes.nil?
        nil
      else
        begin
          DatabaseInfo.load(bytes)
        ensure
          RocksDB.free(bytes)
        end
      end
    end

    def save_db(db : DatabaseInfo)
      @rocksdb.put(KeyValueStore.key_for_database(db.id), db.serialize, HARD_DURABILITY)
    end

    def each_db
      options = RocksDB::ReadOptions.new
      options.iterate_upper_bound = Bytes[PREFIX_DATABASES + 1]
      iter = @rocksdb.iterator(options)
      iter.seek(Bytes[PREFIX_DATABASES])
      while iter.valid?
        yield DatabaseInfo.load(iter.value)
        iter.next
      end
    end

    def get_table(id : UUID)
      bytes = @rocksdb.get(KeyValueStore.key_for_table(id))
      if bytes.nil?
        nil
      else
        begin
          TableInfo.load(bytes)
        ensure
          RocksDB.free(bytes)
        end
      end
    end

    def save_table(table : TableInfo)
      @rocksdb.put(KeyValueStore.key_for_table(table.id), table.serialize, HARD_DURABILITY)

      # Ensure column family exists
      table_data_family(table.id)
      table_metadata_family(table.id)
    end

    def each_table
      options = RocksDB::ReadOptions.new
      options.iterate_upper_bound = Bytes[PREFIX_TABLES + 1]
      iter = @rocksdb.iterator(options)
      iter.seek(Bytes[PREFIX_TABLES])
      while iter.valid?
        yield TableInfo.load(iter.value)
        iter.next
      end
    end

    def save_index(index : IndexInfo)
      @rocksdb.put(table_metadata_family(index.table), KeyValueStore.key_for_table_index(index.id), index.serialize, HARD_DURABILITY)
    end

    def each_index(table_id : UUID)
      options = RocksDB::ReadOptions.new
      options.iterate_upper_bound = KeyValueStore.key_for_table_index_end
      iter = @rocksdb.iterator(table_metadata_family(table_id), options)
      iter.seek(KeyValueStore.key_for_table_index_start)
      while iter.valid?
        yield IndexInfo.load(iter.value)
        iter.next
      end
    end

    def each_index_entry(table_id : UUID, index_id : UUID, index_value_start : Bytes, index_value_end : Bytes, snapshot : RocksDB::BaseSnapshot? = nil)
      options = RocksDB::ReadOptions.new
      options.iterate_upper_bound = KeyValueStore.key_for_table_index_entry_end(index_id, index_value_end)
      options.snapshot = snapshot if snapshot
      iter = @rocksdb.iterator(table_metadata_family(table_id), options)
      iter.seek(KeyValueStore.key_for_table_index_entry_start(index_id, index_value_start))
      while iter.valid?
        index_value, primary_key = KeyValueStore.decompose_index_entry_key(iter.key)
        yield index_value, primary_key
        iter.next
      end
    end

    def snapshot
      @rocksdb.snapshot
    end

    class Transaction
      def initialize(@kv : KeyValueStore, @txn : RocksDB::BaseTransaction)
      end

      def get_row(table_id : UUID, primary_key : Bytes)
        bytes = @txn.get_for_update(@kv.table_data_family(table_id), primary_key)
        if bytes.nil?
          yield nil
        else
          begin
            yield bytes
          ensure
            RocksDB.free(bytes)
          end
        end
      end

      def set_row(table_id : UUID, primary_key : Bytes, data : Bytes)
        @txn.put(@kv.table_data_family(table_id), primary_key, data)
      end

      def delete_row(table_id : UUID, primary_key : Bytes) : Bytes?
        @txn.delete(@kv.table_data_family(table_id), primary_key)
      end

      def set_index_entry(table_id : UUID, index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
        @txn.put(@kv.table_metadata_family(table_id), KeyValueStore.key_for_table_index_entry(index_id, index_value, counter, primary_key), Bytes.new(0))
      end

      def delete_index_entry(table_id : UUID, index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
        @txn.delete(@kv.table_metadata_family(table_id), KeyValueStore.key_for_table_index_entry(index_id, index_value, counter, primary_key))
      end

      def get_table(id : UUID)
        bytes = @txn.get(KeyValueStore.key_for_table(id))
        if bytes.nil?
          nil
        else
          begin
            TableInfo.load(bytes)
          ensure
            RocksDB.free(bytes)
          end
        end
      end

      def save_table(table : TableInfo)
        @txn.put(KeyValueStore.key_for_table(table.id), table.serialize)

        # Ensure column family exists
        @kv.table_data_family(table.id)
        @kv.table_metadata_family(table.id)
      end

      def get_db(id : UUID)
        bytes = @txn.get(KeyValueStore.key_for_database(id))
        if bytes.nil?
          nil
        else
          begin
            DatabaseInfo.load(bytes)
          ensure
            RocksDB.free(bytes)
          end
        end
      end

      def save_db(db : DatabaseInfo)
        @txn.put(KeyValueStore.key_for_database(db.id), db.serialize)
      end
    end

    def transaction(durability : ReQL::Durability = ReQL::Durability::Soft)
      options = {% if flag?(:preview_mt) %}
                  RocksDB::TransactionOptions.new
                {% else %}
                  RocksDB::OptimisticTransactionOptions.new
                {% end %}
      options.set_snapshot = true
      txn = @rocksdb.begin_transaction(get_write_options(durability), options)
      loop do
        begin
          result = yield Transaction.new(self, txn)
          txn.commit
          return result
        rescue ex
          if ex.is_a?(RocksDB::Error) && ex.message.try &.starts_with? "Resource busy"
            txn.begin(get_write_options(durability))
          else
            txn.rollback
            raise ex
          end
        end
      end
    end

    def get_row(table_id : UUID, primary_key : Bytes, snapshot : RocksDB::BaseSnapshot? = nil)
      if snapshot
        options = RocksDB::ReadOptions.new
        options.snapshot = snapshot
        bytes = @rocksdb.get(table_data_family(table_id), primary_key, options)
      else
        bytes = @rocksdb.get(table_data_family(table_id), primary_key)
      end

      if bytes.nil?
        yield nil
      else
        begin
          yield bytes
        ensure
          RocksDB.free(bytes)
        end
      end
    end

    def set_row(table_id : UUID, primary_key : Bytes, data : Bytes, durability : ReQL::Durability = ReQL::Durability::Soft)
      @rocksdb.put(table_data_family(table_id), primary_key, data, get_write_options(durability))
    end

    def delete_row(table_id : UUID, primary_key : Bytes, durability : ReQL::Durability = ReQL::Durability::Soft) : Bytes?
      @rocksdb.delete(table_data_family(table_id), primary_key, get_write_options(durability))
    end

    def each_row(table_id : UUID)
      iter = @rocksdb.iterator(table_data_family(table_id))
      iter.seek_to_first
      while iter.valid?
        yield iter.value
        iter.next
      end
    end

    struct SystemInfo
      property id : UUID = UUID.random
      property data_version : UInt8 = 0
      property name : String

      def initialize
        alphabet = ("A".."Z").to_a + ("a".."z").to_a + ("0".."9").to_a
        @name = System.hostname.strip.gsub(/[^A-Za-z0-9_]/, "_") + "_" + (0...3).map { alphabet.sample }.join
      end

      def serialize
        io = IO::Memory.new
        io.write(@id.bytes.to_slice)
        io.write_bytes(@data_version)
        io.write_bytes(@name.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@name.to_slice)
        io.to_slice
      end

      def self.load(bytes : Bytes) : SystemInfo
        io = IO::Memory.new(bytes, false)
        obj = new
        id_bytes = Bytes.new(16)
        io.read_fully(id_bytes)
        obj.id = UUID.new(id_bytes)
        obj.data_version = io.read_bytes(UInt8)
        obj.name = io.read_string(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
        obj
      end
    end

    struct DatabaseInfo
      property id : UUID = UUID.random
      property name : String = ""

      def serialize
        io = IO::Memory.new
        io.write(@id.bytes.to_slice)
        io.write_bytes(@name.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@name.to_slice)
        io.to_slice
      end

      def self.load(bytes : Bytes) : DatabaseInfo
        io = IO::Memory.new(bytes, false)
        obj = new
        id_bytes = Bytes.new(16)
        io.read_fully(id_bytes)
        obj.id = UUID.new(id_bytes)
        obj.name = io.read_string(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
        obj
      end
    end

    struct TableInfo
      property id : UUID = UUID.random
      property db : UUID = UUID.empty
      property name : String = ""
      property primary_key : String = "id"
      property durability : ReQL::Durability = ReQL::Durability::Hard

      def serialize
        io = IO::Memory.new
        io.write(@id.bytes.to_slice)
        io.write(@db.bytes.to_slice)
        io.write_bytes(@name.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@name.to_slice)
        io.write_bytes(@primary_key.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@primary_key.to_slice)
        io.write_bytes(@durability == ReQL::Durability::Soft ? 1u8 : 0u8)
        io.to_slice
      end

      def self.load(bytes : Bytes) : TableInfo
        io = IO::Memory.new(bytes, false)
        obj = new
        id_bytes = Bytes.new(16)
        io.read_fully(id_bytes)
        obj.id = UUID.new(id_bytes)
        db_bytes = Bytes.new(16)
        io.read_fully(db_bytes)
        obj.db = UUID.new(db_bytes)
        obj.name = io.read_string(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
        obj.primary_key = io.read_string(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
        obj.durability = io.read_bytes(UInt8) != 0u8 ? ReQL::Durability::Soft : ReQL::Durability::Hard
        obj
      end
    end

    struct IndexInfo
      property id : UUID = UUID.random
      property table : UUID = UUID.empty
      property name : String = ""
      property ready : Bool = false
      property multi : Bool = false
      property function : ReQL::Func = ReQL::ReqlFunc.new([1i64], ReQL::VarTerm.new([1i64.as(ReQL::Term::Type)], nil).as(ReQL::Term))

      def serialize
        io = IO::Memory.new
        io.write(@id.bytes.to_slice)
        io.write(@table.bytes.to_slice)
        io.write_bytes(@name.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@name.to_slice)
        io.write_bytes(@ready ? 1u8 : 0u8)
        io.write_bytes(@multi ? 1u8 : 0u8)
        function_bytes = @function.encode
        io.write_bytes(function_bytes.size.to_u32, IO::ByteFormat::LittleEndian)
        io.write(function_bytes)
        io.to_slice
      end

      def self.load(bytes : Bytes) : IndexInfo
        io = IO::Memory.new(bytes, false)
        obj = new
        id_bytes = Bytes.new(16)
        io.read_fully(id_bytes)
        obj.id = UUID.new(id_bytes)
        table_bytes = Bytes.new(16)
        io.read_fully(table_bytes)
        obj.table = UUID.new(table_bytes)
        obj.name = io.read_string(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
        obj.ready = io.read_bytes(UInt8) != 0u8
        obj.multi = io.read_bytes(UInt8) != 0u8
        function_bytes = Bytes.new(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
        io.read_fully(function_bytes)
        obj.function = ReQL::Func.decode(function_bytes)
        obj
      end
    end
  end
end
