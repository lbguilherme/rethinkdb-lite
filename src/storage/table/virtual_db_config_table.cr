require "./virtual_table"

module Storage
  class VirtualDbConfigTable < VirtualTable
    def initialize(@manager : Manager)
      super("db_config")
    end

    def insert(obj : Hash)
      info = decode(obj)
      @manager.create_db(info.name, info.id) do |current_info|
        duplicated_primary_key_error("id", encode(current_info), obj)
      end
    end

    def replace(key, &block : Hash(String, ReQL::Datum) -> Hash(String, ReQL::Datum))
      raise "TODO"
    end

    private def encode(info : KeyValueStore::DatabaseInfo)
      ReQL::Datum.new({
        "id"   => info.id.to_s,
        "name" => info.name,
      }).hash_value
    end

    private def decode(obj)
      info = KeyValueStore::DatabaseInfo.new
      check_extra_keys(obj, {"id", "name"})
      info.id = extract_uuid(obj, "id")
      info.name = extract_string(obj, "name", "a db name")
      info
    end

    def get(key)
      id = UUID.new(key.string_value) rescue return nil
      encode(@manager.get_db(id))
    end

    def scan
      @manager.databases.each_value do |db|
        yield encode(db.info)
      end
    end
  end
end
