module Storage
  class VirtualDbConfigTable < AbstractTable
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
        block.call ReQL::Datum.new({
          "id"   => db.id,
          "name" => db.name,
        }).hash_value
      end
    end
  end
end
