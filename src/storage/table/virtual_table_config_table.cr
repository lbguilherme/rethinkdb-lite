module Storage
  class VirtualTableConfigTable < AbstractTable
    def initialize(@manager : Manager)
    end

    def replace(key, &block : Hash(String, ReQL::Datum) -> Hash(String, ReQL::Datum))
      raise "TODO"
    end

    def delete(key) : Bool
      raise "TODO"
    end

    def scan
      @manager.databases.each_value do |db|
        db.tables.each_value do |table|
          yield ReQL::Datum.new({
            "db"          => db.info.name,
            "durability"  => table.soft_durability ? "soft" : "hard",
            "id"          => table.id.to_s,
            "indexes"     => [] of String,
            "name"        => table.name,
            "primary_key" => table.primary_key,
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
      end
    end
  end
end
