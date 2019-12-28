module Storage
  class KeyValueStore
    private def migrate
      if @system_info.data_version == 0
        migrate_v0_to_v1
      end

      if @system_info.data_version == 1
        migrate_v1_to_v2
      end
    end

    private def migrate_v0_to_v1
      @system_info.data_version = 1
      @rocksdb.put(KeyValueStore.key_for_system_info, @system_info.serialize)
    end

    private def migrate_v1_to_v2
      batch = RocksDB::WriteBatch.new
      options = RocksDB::ReadOptions.new
      options.iterate_upper_bound = Bytes[PREFIX_TABLES + 1]
      iter = @rocksdb.iterator(options)
      iter.seek(Bytes[PREFIX_TABLES])
      while iter.valid?
        io = IO::Memory.new
        io.write(iter.value)
        io.write_bytes(0u8)
        batch.put(iter.key, io.to_slice)
        iter.next
      end

      @system_info.data_version = 2
      batch.put(KeyValueStore.key_for_system_info, @system_info.serialize)
      @rocksdb.write(batch)
    end
  end
end
