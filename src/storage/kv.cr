require "uuid"
require "file_utils"
require "rocksdb"

module Storage
  class KeyValueStore
    PREFIX_SYSTEM_INFO = 0u8
    PREFIX_DATABASES   = 1u8
    PREFIX_TABLES      = 2u8
    PREFIX_TABLE_DATA  = 3u8
    TABLE_PREFIX_DATA  = 0u8

    SOFT_DURABILITY = RocksDB::WriteOptions.new
    SOFT_DURABILITY.disable_wal = true
    SOFT_DURABILITY.sync = false

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

    def self.key_for_table_data(table_id : UUID, primary_key : Bytes)
      io = IO::Memory.new
      io.write_bytes(PREFIX_TABLE_DATA)
      io.write(table_id.bytes.to_slice)
      io.write_bytes(TABLE_PREFIX_DATA)
      io.write(primary_key)
      io.to_slice
    end

    def self.key_for_table_data_start(table_id : UUID)
      io = IO::Memory.new
      io.write_bytes(PREFIX_TABLE_DATA)
      io.write(table_id.bytes.to_slice)
      io.write_bytes(TABLE_PREFIX_DATA)
      io.to_slice
    end

    def self.key_for_table_data_end(table_id : UUID)
      io = IO::Memory.new
      io.write_bytes(PREFIX_TABLE_DATA)
      io.write(table_id.bytes.to_slice)
      io.write_bytes(TABLE_PREFIX_DATA + 1)
      io.to_slice
    end

    property system_info

    @rocksdb : RocksDB::OptimisticTransactionDatabase

    def initialize(path)
      options = RocksDB::Options.new
      options.create_if_missing = true
      options.paranoid_checks = true

      FileUtils.mkdir_p path
      @rocksdb = RocksDB::OptimisticTransactionDatabase.open(path, options)

      system_info_bytes = @rocksdb.get(KeyValueStore.key_for_system_info)
      @system_info = system_info_bytes.nil? ? SystemInfo.new : SystemInfo.load(system_info_bytes)

      migrate
    end

    def close
      @rocksdb.close
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

    class Transaction
      def initialize(@txn : RocksDB::Transaction)
      end

      def get_row(table_id : UUID, primary_key : Bytes)
        bytes = @txn.get_for_update(KeyValueStore.key_for_table_data(table_id, primary_key))
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
        @txn.put(KeyValueStore.key_for_table_data(table_id, primary_key), data)
      end

      def delete_row(table_id : UUID, primary_key : Bytes) : Bytes?
        @txn.delete(KeyValueStore.key_for_table_data(table_id, primary_key))
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

    def transaction(soft_durability : Bool = false)
      txn = @rocksdb.begin_transaction(soft_durability ? SOFT_DURABILITY : HARD_DURABILITY)
      loop do
        begin
          result = yield Transaction.new(txn)
          txn.commit
          return result
        rescue ex
          if ex.is_a?(RocksDB::Error) && ex.message.try &.starts_with? "Resource busy"
            txn.begin
          else
            txn.rollback
            raise ex
          end
        end
      end
    end

    def get_row(table_id : UUID, primary_key : Bytes)
      bytes = @rocksdb.get(KeyValueStore.key_for_table_data(table_id, primary_key))
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

    def set_row(table_id : UUID, primary_key : Bytes, data : Bytes, soft_durability : Bool = false)
      @rocksdb.put(KeyValueStore.key_for_table_data(table_id, primary_key), data, soft_durability ? SOFT_DURABILITY : HARD_DURABILITY)
    end

    def delete_row(table_id : UUID, primary_key : Bytes, soft_durability : Bool = false) : Bytes?
      @rocksdb.delete(KeyValueStore.key_for_table_data(table_id, primary_key), soft_durability ? SOFT_DURABILITY : HARD_DURABILITY)
    end

    def each_row(table_id : UUID)
      options = RocksDB::ReadOptions.new
      options.iterate_upper_bound = KeyValueStore.key_for_table_data_end(table_id)
      iter = @rocksdb.iterator(options)
      iter.seek(KeyValueStore.key_for_table_data_start(table_id))
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
      property soft_durability : Bool = false

      def serialize
        io = IO::Memory.new
        io.write(@id.bytes.to_slice)
        io.write(@db.bytes.to_slice)
        io.write_bytes(@name.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@name.to_slice)
        io.write_bytes(@primary_key.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@primary_key.to_slice)
        io.write_bytes(@soft_durability ? 1u8 : 0u8)
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
        obj.soft_durability = io.read_bytes(UInt8) != 0u8
        obj
      end
    end
  end
end
