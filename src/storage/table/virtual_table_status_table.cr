require "./virtual_table"

module Storage
  struct VirtualTableStatusTable < VirtualTable
    def initialize(manager : Manager)
      super("table_status", manager)
    end

    private def encode(info : KeyValueStore::TableInfo)
      ReQL::Datum.new({
        "db"          => @manager.database_by_id[info.db]?.try &.info.name || info.db.to_s,
        "id"          => info.id.to_s,
        "name"        => info.name,
        "raft_leader" => @manager.system_info.name,
        "shards"      => [
          {
            "primary_replicas" => [@manager.system_info.name],
            "replicas"         => [
              {
                "server" => @manager.system_info.name,
                "state"  => "ready",
              },
            ],
          },
        ],
        "status" => {
          "all_replicas_ready"       => true,
          "ready_for_outdated_reads" => true,
          "ready_for_reads"          => true,
          "ready_for_writes"         => true,
        },
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
