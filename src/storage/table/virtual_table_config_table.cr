module Storage
  class VirtualTableConfigTable < AbstractTable
    def initialize(@manager : Manager)
    end

    def insert(obj : Hash)
      raise "TODO"
    end

    def replace(key, &block : Hash(String, ReQL::Datum) -> Hash(String, ReQL::Datum))
      raise "TODO"
    end

    def scan
      @manager.databases.each_value do |db|
        db.tables.each_value do |table|
          yield ReQL::Datum.new({
            "db"          => db.info.name,
            "id"          => table.id.to_s,
            "name"        => table.name,
            "raft_leader" => @manager.system_info.name,
            "shards"      => [
              {
                "primary_replicas" => [
                  @manager.system_info.name,
                ],
                "replicas" => [
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
      end
    end
  end
end
