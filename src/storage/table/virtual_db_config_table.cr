module Storage
  class VirtualDbConfigTable < AbstractTable
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
        yield ReQL::Datum.new({
          "id"   => db.info.id.to_s,
          "name" => db.info.name,
        }).hash_value
      end
    end
  end
end
