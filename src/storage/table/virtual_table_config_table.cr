module Storage
  class VirtualTableConfigTable < VirtualTable
    def initialize(@manager : Manager)
      super("table_config")
    end

    def replace(key)
      yield nil
      raise "TODO"
    end

    private def encode(info : KeyValueStore::TableInfo)
      ReQL::Datum.new({
        "db"          => @manager.kv.get_db(info.db).try &.name || info.db.to_s,
        "durability"  => info.soft_durability ? "soft" : "hard",
        "id"          => info.id.to_s,
        "indexes"     => [] of String,
        "name"        => info.name,
        "primary_key" => info.primary_key,
        "shards"      => [
          {
            "nonvoting_replicas" => [] of String,
            "primary_replica"    => @manager.system_info.name,
            "replicas"           => [@manager.system_info.name],
          },
        ],
        "write_acks" => "single",
        "write_hook" => nil,
      }).hash_value
    end

    def get(key)
      id = UUID.new(key.string_value) rescue return nil
      encode(@manager.kv.get_table(id))
    end

    def scan
      @manager.kv.each_table do |info|
        yield encode(info)
      end
    end
  end
end
