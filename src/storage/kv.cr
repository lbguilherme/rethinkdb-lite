require "uuid"
require "file_utils"
require "rocksdb"
require "../reql/helpers/table_writter"
require "../reql/executor/func"
require "../reql/executor/reql_func"
require "../reql/terms/var"

module Storage
  class KeyValueStore
    PREFIX_SYSTEM_INFO = 0u8
    PREFIX_DATABASES   = 1u8
    PREFIX_TABLES      = 2u8
    PREFIX_INDICES     = 3u8

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

    def self.key_for_table_index(table_id : UUID, index_id : UUID)
      io = IO::Memory.new(34)
      io.write_bytes(PREFIX_INDICES)
      io.write(table_id.bytes.to_slice)
      io.write_bytes(0u8)
      io.write(index_id.bytes.to_slice)
      io.to_slice
    end

    def self.key_for_table_index_start(table_id : UUID)
      io = IO::Memory.new(18)
      io.write_bytes(PREFIX_INDICES)
      io.write(table_id.bytes.to_slice)
      io.write_bytes(0u8)
      io.to_slice
    end

    def self.key_for_table_index_end(table_id : UUID)
      io = IO::Memory.new(18)
      io.write_bytes(PREFIX_INDICES)
      io.write(table_id.bytes.to_slice)
      io.write_bytes(1u8)
      io.to_slice
    end

    def self.key_for_table_index_entry(index_value : Bytes, counter : Int32, primary_key : Bytes)
      io = IO::Memory.new(index_value.size + 5 + primary_key.size + 4)
      io.write(index_value)
      io.write_bytes(0u8)
      io.write_bytes(counter, IO::ByteFormat::LittleEndian)
      io.write(primary_key)
      io.write_bytes(primary_key.size.to_u32, IO::ByteFormat::LittleEndian)
      io.to_slice
    end

    def self.key_for_table_index_entry_start(index_value : Bytes)
      io = IO::Memory.new(index_value.size + 1)
      io.write(index_value)
      io.write_bytes(0u8)
      io.to_slice
    end

    def self.key_for_table_index_entry_end(index_value : Bytes)
      io = IO::Memory.new(index_value.size + 1)
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

      index_value = Bytes.new(index_entry_key.size - 1 - primary_key.size - 4 - 4)
      io.seek(1 + 16 + 1)
      io.read_fully(index_value)

      return {index_value, primary_key}
    end

    property system_info
    getter database_path

    def initialize(@database_path : String)
      @options = RocksDB::Options.new
      @options.create_if_missing = true

      # This is supposed to improve perfomance. (does it?)
      @options.paranoid_checks = false

      # This is required to injest SST files for index building
      @options.allow_ingest_behind = true

      {% if flag?(:preview_mt) %}
        @options.enable_pipelined_write = false
        @options.increase_parallelism(16)
        @options.max_background_jobs = 4

        # Older RocksDB 5.17 doesn't support those.
        # @options.unordered_write = true
        # @options.avoid_unnecessary_blocking_io = true
      {% end %}

      FileUtils.mkdir_p @database_path

      if File.exists? Path.new(@database_path, "CURRENT")
        families = RocksDB::Database.list_column_families(@database_path, @options).map { |name| {name, @options} }.to_h
      else
        families = {"default" => @options}
      end

      @rocksdb = RocksDB::Database.open(@database_path, @options, families)

      system_info_bytes = @rocksdb.get(KeyValueStore.key_for_system_info)
      @system_info = system_info_bytes.nil? ? SystemInfo.new : SystemInfo.load(system_info_bytes)

      migrate
    end

    @table_data_family_cache = {} of UUID => RocksDB::ColumnFamilyHandle

    def table_data_family(table_id : UUID)
      handle = @table_data_family_cache[table_id]?
      return handle if handle
      name = "table.#{table_id}.data"
      handle = @rocksdb.family_handle?(name)
      handle = @rocksdb.create_column_family(name, @options) unless handle
      @table_data_family_cache[table_id] = handle
    end

    @table_index_family_cache = {} of {UUID, UUID} => RocksDB::ColumnFamilyHandle

    def table_index_family(table_id : UUID, index_id : UUID)
      handle = @table_index_family_cache[{table_id, index_id}]?
      return handle if handle
      name = "table.#{table_id}.index.#{index_id}"
      handle = @rocksdb.family_handle?(name)
      handle = @rocksdb.create_column_family(name, @options) unless handle
      @table_index_family_cache[{table_id, index_id}] = handle
    end

    def drop_index_data(table_id : UUID, index_id : UUID)
      name = "table.#{table_id}.index.#{index_id}"
      @rocksdb.drop_column_family(name)
      @table_index_family_cache.delete({table_id, index_id})
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
      @rocksdb.put(KeyValueStore.key_for_table_index(index.table, index.id), index.serialize, HARD_DURABILITY)
    end

    def each_index(table_id : UUID)
      options = RocksDB::ReadOptions.new
      options.iterate_upper_bound = KeyValueStore.key_for_table_index_end(table_id)
      iter = @rocksdb.iterator(options)
      iter.seek(KeyValueStore.key_for_table_index_start(table_id))
      while iter.valid?
        yield IndexInfo.load(iter.value)
        iter.next
      end
    end

    def each_index_entry(table_id : UUID, index_id : UUID, index_value_start : Bytes, index_value_end : Bytes, snapshot : RocksDB::BaseSnapshot? = nil)
      options = RocksDB::ReadOptions.new
      options.iterate_upper_bound = KeyValueStore.key_for_table_index_entry_end(index_value_end)
      options.snapshot = snapshot if snapshot
      iter = @rocksdb.iterator(table_index_family(table_id, index_id), options)
      iter.seek(KeyValueStore.key_for_table_index_entry_start(index_value_start))
      while iter.valid?
        index_value, primary_key = KeyValueStore.decompose_index_entry_key(iter.key)
        yield index_value, primary_key
        iter.next
      end
    end

    def snapshot
      @rocksdb.snapshot
    end

    class WriteBatch
      def initialize(@kv : KeyValueStore)
        @batch = RocksDB::WriteBatch.new
      end

      def raw_batch
        @batch
      end

      def set_row(table_id : UUID, primary_key : Bytes, data : Bytes)
        @batch.put(@kv.table_data_family(table_id), primary_key, data)
      end

      def delete_row(table_id : UUID, primary_key : Bytes) : Bytes?
        @batch.delete(@kv.table_data_family(table_id), primary_key)
      end

      def set_index_entry(table_id : UUID, index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
        @batch.put(@kv.table_index_family(table_id, index_id), KeyValueStore.key_for_table_index_entry(index_value, counter, primary_key), Bytes.new(0))
      end

      def delete_index_entry(table_id : UUID, index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
        @batch.delete(@kv.table_index_family(table_id, index_id), KeyValueStore.key_for_table_index_entry(index_value, counter, primary_key))
      end
    end

    def create_batch
      WriteBatch.new(self)
    end

    def write_batch(batch, durability : ReQL::Durability = ReQL::Durability::Soft)
      @rocksdb.write(batch.raw_batch, get_write_options(durability))
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

    def set_index_entry(table_id : UUID, index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
      @rocksdb.put(table_index_family(table_id, index_id), KeyValueStore.key_for_table_index_entry(index_value, counter, primary_key), Bytes.new(0))
    end

    def delete_index_entry(table_id : UUID, index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
      @rocksdb.delete(table_index_family(table_id, index_id), KeyValueStore.key_for_table_index_entry(index_value, counter, primary_key))
    end

    def set_row(table_id : UUID, primary_key : Bytes, data : Bytes, durability : ReQL::Durability = ReQL::Durability::Soft)
      @rocksdb.put(table_data_family(table_id), primary_key, data, get_write_options(durability))
    end

    def delete_row(table_id : UUID, primary_key : Bytes, durability : ReQL::Durability = ReQL::Durability::Soft) : Bytes?
      @rocksdb.delete(table_data_family(table_id), primary_key, get_write_options(durability))
    end

    def each_row(table_id : UUID)
      read_options = RocksDB::ReadOptions.new
      read_options.readahead_size = 1024 * 1024
      iter = @rocksdb.iterator(table_data_family(table_id), read_options)
      iter.seek_to_first
      while iter.valid?
        yield iter.key, iter.value
        iter.next
      end
    end

    class IndexBuilder
      def initialize(@kv : KeyValueStore)
        options = RocksDB::Options.new
        options.create_if_missing = true
        options.paranoid_checks = false

        @tmp_path = File.join(@kv.database_path, "tmp", Random::Secure.hex)
        FileUtils.mkdir_p @tmp_path
        @tmp = RocksDB::Database.open(@tmp_path, options)
      end

      def set_index_entry(table_id : UUID, index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
        @tmp.put(KeyValueStore.key_for_table_index_entry(index_value, counter, primary_key), Bytes.new(0), MINIMAL_DURABILITY)
      end

      def delete_index_entry(table_id : UUID, index_id : UUID, index_value : Bytes, counter : Int32, primary_key : Bytes)
      end

      def produce_sst_file
        sst_file_path = File.join(@kv.database_path, "tmp", Random::Secure.hex + "_sst")
        sst_file_writer = RocksDB::SstFileWriter.new(RocksDB::EnvOptions.new, RocksDB::Options.new)
        sst_file_writer.open(sst_file_path)

        iter = @tmp.iterator
        iter.seek_to_first

        # Empty index
        return nil unless iter.valid?

        while iter.valid?
          sst_file_writer.put(iter.key, iter.value)
          iter.next
          Fiber.yield
        end

        sst_file_writer.finish
        sst_file_path
      end

      def close
        @tmp.close
        FileUtils.rm_rf @tmp_path
      end
    end

    def build_index(table_id : UUID, index_id : UUID)
      builder = IndexBuilder.new(self)

      yield builder

      sst_file = builder.produce_sst_file
      builder.close

      if sst_file
        ingest_options = RocksDB::IngestExternalFileOptions.new
        ingest_options.ingest_behind = true
        ingest_options.move_files = true
        @rocksdb.ingest_external_file(table_index_family(table_id, index_id), [sst_file], ingest_options)
        FileUtils.rm_rf sst_file
      end
    end

    def estimated_table_count(table_id : UUID)
      @rocksdb.property_int(table_data_family(table_id), "rocksdb.estimate-num-keys").not_nil!.to_i64
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
