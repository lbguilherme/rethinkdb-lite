module Storage
  class VirtualTableConfigTable < AbstractTable
    def insert(obj : Hash)
      raise ""
    end

    def get(key)
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
            "raft_leader" => "",
            "shards"      => Array(ReQL::Datum::Type){
              Hash(String, ReQL::Datum::Type){
                "primary_replicas" => Array(ReQL::Datum::Type){
                  "",
                }.as(ReQL::Datum::Type),
                "replicas" => Array(ReQL::Datum::Type){
                  Hash(String, ReQL::Datum::Type){
                    "server" => "",
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

# "db":  "zig" ,
# "id":  "056503a2-d1db-4c14-a730-f889fdcdfa87" ,
# "name":  "stock_interactions" ,
# "raft_leader":  "zig_rethink99" ,
# "shards": [
# {
# "primary_replicas": [
# "zig_rethink99"
# ] ,
# "replicas": [
# {
# "server":  "zig_rethink99" ,
# "state":  "ready"
# }
# ]
# }
# ] ,
# "status": {
# "all_replicas_ready": true ,
# "ready_for_outdated_reads": true ,
# "ready_for_reads": true ,
# "ready_for_writes": true
# }
