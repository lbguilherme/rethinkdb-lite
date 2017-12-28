module Storage
  class VirtualTableConfigTable < AbstractTable
    def insert(obj : Hash)
      raise ""
    end

    def replace(key, &block : ReQL::Datum::Type -> ReQL::Datum::Type)
      raise ""
    end

    def scan(&block : ReQL::Datum::Type ->)
      Config.databases.each do |db|
        db.tables.each do |table|
          block.call Hash(String, ReQL::Datum::Type){
            "db"          => db.name,
            "id"          => table.id,
            "name"        => table.name,
            "raft_leader" => Config.server_info.name,
            "shards"      => Array(ReQL::Datum::Type){
              Hash(String, ReQL::Datum::Type){
                "primary_replicas" => Array(ReQL::Datum::Type){
                  Config.server_info.name,
                }.as(ReQL::Datum::Type),
                "replicas" => Array(ReQL::Datum::Type){
                  Hash(String, ReQL::Datum::Type){
                    "server" => Config.server_info.name,
                    "state"  => "ready",
                  }.as(ReQL::Datum::Type),
                }.as(ReQL::Datum::Type),
              }.as(ReQL::Datum::Type),
            }.as(ReQL::Datum::Type),
            "status" => Hash(String, ReQL::Datum::Type){
              "all_replicas_ready"       => true,
              "ready_for_outdated_reads" => true,
              "ready_for_reads"          => true,
              "ready_for_writes"         => true,
            }.as(ReQL::Datum::Type),
          }.as(ReQL::Datum::Type)
        end
      end
    end
  end
end
