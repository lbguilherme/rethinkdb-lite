module Storage
  class VirtualTableConfigTable < AbstractTable
    def initialize(@config : Config)
    end

    def insert(obj : Hash)
      raise "TODO"
    end

    def replace(key, &block : Hash(String, ReQL::Datum) -> Hash(String, ReQL::Datum))
      raise "TODO"
    end

    def scan(&block : Hash(String, ReQL::Datum) ->)
      @config.databases.each do |db|
        db.tables.each do |table|
          block.call ReQL::Datum.new({
            "db"          => db.name,
            "id"          => table.id,
            "name"        => table.name,
            "raft_leader" => @config.server_info.name,
            "shards"      => [
              {
                "primary_replicas" => [
                  @config.server_info.name,
                ],
                "replicas" => [
                  {
                    "server" => @config.server_info.name,
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
