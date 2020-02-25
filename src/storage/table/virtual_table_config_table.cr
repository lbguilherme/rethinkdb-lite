require "./virtual_table"

module Storage
  struct VirtualTableConfigTable < VirtualTable
    def initialize(manager : Manager)
      super("table_config", manager)
    end

    def replace(key, durability : ReQL::Durability? = nil)
      id = extract_uuid({"id" => key}, "id")

      after_commit = nil

      @manager.kv.transaction do |t|
        existing_info = t.get_table(id)
        new_row = yield encode(existing_info)

        if new_row.nil?
          # Delete
          raise "TODO: Delete table"
        end

        if new_row["db"]? == "rethinkdb"
          raise ReQL::OpFailedError.new("Database `rethinkdb` is special; you can't create new tables in it")
        end
        info = decode(new_row)

        if existing_info.nil?
          # Insert
          db = uninitialized Storage::Manager::Database
          @manager.lock.synchronize do
            db = @manager.databases[new_row["db"].string_value]
            if db.tables.has_key?(info.name)
              raise ReQL::OpFailedError.new("Table `#{info.name}` already exists")
            end
          end

          t.save_table(info)

          after_commit = ->do
            @manager.lock.synchronize do
              table = @manager.table_by_id[info.id] = db.tables[info.name] = Manager::Table.new(info, db.info.name)
              table.impl = PhysicalTable.new(@manager, table)
            end
          end
          next
        end

        if existing_info != info
          # Update
          raise "TODO: Update table"
        end
      end

      after_commit.try &.call
    end

    private def encode(info : KeyValueStore::TableInfo)
      ReQL::Datum.new({
        "db"          => @manager.database_by_id[info.db]?.try &.info.name || info.db.to_s,
        "durability"  => info.durability == ReQL::Durability::Hard ? "hard" : info.durability == ReQL::Durability::Soft ? "soft" : "minimal",
        "id"          => info.id.to_s,
        "indexes"     => [] of String,
        "name"        => info.name,
        "primary_key" => info.primary_key,
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

    private def decode(obj)
      info = KeyValueStore::TableInfo.new
      check_extra_keys(obj, {"id", "db", "name", "primary_key", "durability", "shards"})
      info.id = extract_uuid(obj, "id")
      info.db = extract_db_reference(obj, "db")
      info.name = extract_table_name(obj, "name")
      if obj.has_key? "primary_key"
        info.primary_key = extract_string(obj, "primary_key")
      end
      if obj.has_key? "durability"
        info.durability = extract_durability(obj, "durability")
      end
      info
    end

    def get(key)
      id = UUID.new(key.string_value) rescue return nil
      encode(@manager.kv.get_table(id))
    end

    def scan
      @manager.kv.each_table do |info|
        yield encode(info)
      end
    end
  end
end
