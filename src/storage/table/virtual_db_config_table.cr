module Storage
  class VirtualDbConfigTable < AbstractTable
    def initialize(@config : Config)
    end

    def insert(obj : Hash)
      raise ""
    end

    def replace(key, &block : ReQL::Datum::Type -> ReQL::Datum::Type)
      raise ""
    end

    def scan(&block : ReQL::Datum::Type ->)
      @config.databases.each do |db|
        block.call Hash(String, ReQL::Datum::Type){
          "id"   => db.id,
          "name" => db.name,
        }.as(ReQL::Datum::Type)
      end
    end
  end
end
