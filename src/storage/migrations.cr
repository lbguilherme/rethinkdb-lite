module Storage
  class KeyValueStore
    private def migrate
      if @system_info.data_version == 0
        migrate_v0_to_v1
      end
    end

    private def migrate_v0_to_v1
      @system_info.data_version = 1
      @rocksdb.put(KeyValueStore.key_for_system_info, @system_info.serialize)
    end
  end
end
