require "uuid"
require "../rocksdb"

module Storage
  class KeyValueStore

    PREFIX_SYSTEM_INFO = 0u8
    PREFIX_DATABASES = 1u8
    PREFIX_TABLES = 2u8
    PREFIX_TABLE_DATA = 3u8
    TABLE_PREFIX_DATA = 0u8

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

    @rocksdb : RocksDb::OptimisticTransactionDatabase

    def initialize(path)
      options = RocksDb::Options.new
      options.create_if_missing = true
      options.paranoid_checks = true

      @rocksdb = RocksDb::OptimisticTransactionDatabase.open(options, path)

      system_info_bytes = @rocksdb.get(KeyValueStore.key_for_system_info)
      @system_info = system_info_bytes.nil? ? SystemInfo.new : SystemInfo.load(system_info_bytes)

      if @system_info.data_version == 0
        migrate_v0_to_v1
      end
    end

    def close
      @rocksdb.close
    end

    def get_db(id : UUID)
      bytes = @rocksdb.get(KeyValueStore.key_for_database(id))
      bytes.nil? ? nil : DatabaseInfo.load(bytes)
    end

    def save_db(db : DatabaseInfo)
      @rocksdb.put(KeyValueStore.key_for_database(db.id), db.serialize)
    end

    def each_db
      options = RocksDb::ReadOptions.new
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
      bytes.nil? ? nil : TableInfo.load(bytes)
    end

    def save_table(table : TableInfo)
      @rocksdb.put(KeyValueStore.key_for_table(table.id), table.serialize)
    end

    def each_table
      options = RocksDb::ReadOptions.new
      options.iterate_upper_bound = Bytes[PREFIX_TABLES + 1]
      iter = @rocksdb.iterator(options)
      iter.seek(Bytes[PREFIX_TABLES])
      while iter.valid?
        yield TableInfo.load(iter.value)
        iter.next
      end
    end

    class DataTransaction
      def initialize(@txn : RocksDb::Transaction)
      end

      def get_row(table_id : UUID, primary_key : Bytes) : Bytes?
        @txn.get(KeyValueStore.key_for_table_data(table_id, primary_key))
      end

      def set_row(table_id : UUID, primary_key : Bytes, data : Bytes)
        @txn.put(KeyValueStore.key_for_table_data(table_id, primary_key), data)
      end
    end

    def data_transaction
      txn = @rocksdb.begin_transaction
      loop do
        begin
          yield DataTransaction.new(txn)
          txn.commit
          break
        rescue ex
          if ex.is_a?(RocksDb::Error) && ex.message.try &.starts_with? "Resource busy"
            txn.begin
          else
            txn.rollback
            raise ex
          end
        end
      end
    end

    def get_row(table_id : UUID, primary_key : Bytes) : Bytes?
      @rocksdb.get(KeyValueStore.key_for_table_data(table_id, primary_key))
    end

    def set_row(table_id : UUID, primary_key : Bytes, data : Bytes)
      @rocksdb.put(KeyValueStore.key_for_table_data(table_id, primary_key), data)
    end

    def each_row(table_id : UUID)
      options = RocksDb::ReadOptions.new
      options.iterate_upper_bound = KeyValueStore.key_for_table_data_end(table_id)
      iter = @rocksdb.iterator(options)
      iter.seek(KeyValueStore.key_for_table_data_start(table_id))
      while iter.valid?
        yield iter.value
        iter.next
      end
    end

    private def migrate_v0_to_v1
      @system_info.data_version = 1
      @rocksdb.put(KeyValueStore.key_for_system_info, @system_info.serialize)
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

      def serialize
        io = IO::Memory.new
        io.write(@id.bytes.to_slice)
        io.write(@db.bytes.to_slice)
        io.write_bytes(@name.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@name.to_slice)
        io.write_bytes(@primary_key.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(@primary_key.to_slice)
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
        obj
      end
    end
  end
end
