module Storage
  struct VirtualServerConfigTable < VirtualTable
    def initialize(manager : Manager)
      super("server_config", manager)
    end

    private def encode(info : KeyValueStore::SystemInfo)
      ReQL::Datum.new({
        "cache_size_mb" => "auto",
        "id"            => @manager.system_info.id.to_s,
        "name"          => @manager.system_info.name,
        "tags"          => [
          "default",
        ],
      }).hash_value
    end

    def get(key)
      info = @manager.system_info
      id = UUID.new(key.string_value) rescue return nil
      encode(info.id == id ? info : nil)
    end

    def scan
      yield encode(@manager.system_info)
    end
  end
end
