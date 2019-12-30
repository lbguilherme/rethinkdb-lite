require "./virtual_table"

module Storage
  struct VirtualDbConfigTable < VirtualTable
    def initialize(manager : Manager)
      super("db_config", manager)
    end

    def replace(key)
      id = extract_uuid({"id" => key}, "id")

      @manager.lock.synchronize do
        after_commit = nil

        @manager.kv.transaction do |t|
          existing_info = t.get_db(id)
          new_row = yield encode(existing_info)

          if new_row.nil?
            raise "TODO: Delete database"
          else
            info = decode(new_row)

            if existing_info.nil?
              if info.name == "rethinkdb" || @manager.databases.has_key?(info.name)
                raise ReQL::OpFailedError.new("Database `#{info.name}` already exists")
              end

              t.save_db(info)

              after_commit = ->{ @manager.databases[info.name] = Manager::Database.new(info) }
            else
              raise "TODO: Update database"
            end
          end
        end

        after_commit.try &.call
      end
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
      encode(@manager.kv.get_db(id))
    end

    def scan
      @manager.kv.each_db do |info|
        yield encode(info)
      end
    end
  end
end
