require "json"
require "./abstract_table"

module Storage
  struct PhysicalTable < AbstractTable
    def initialize(@manager : Manager, @table : Manager::Table)
    end

    def primary_key
      @table.info.primary_key
    end

    def get(key)
      @manager.kv.get_row(@table.info.id, key.serialize) do |data|
        data.nil? ? nil : ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end

    def replace(key, durability : ReQL::Durability? = nil)
      key_data = key.serialize

      @manager.kv.transaction(durability || @table.info.durability) do |t|
        existing_row = t.get_row(@table.info.id, key_data) do |existing_row_data|
          if existing_row_data.nil?
            nil
          else
            ReQL::Datum.unserialize(IO::Memory.new(existing_row_data)).hash_value
          end
        end

        new_row = yield existing_row

        if new_row.nil?
          unless existing_row.nil?
            t.delete_row(@table.info.id, key_data)
          end
        else
          if existing_row != new_row
            t.set_row(@table.info.id, key_data, ReQL::Datum.new(new_row).serialize)
          end
        end
      end
    end

    def scan
      @manager.kv.each_row(@table.info.id) do |data|
        yield ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end

    def create_index(name : String, function : ReQL::Func)
      info = KeyValueStore::IndexInfo.new
      info.name = name
      info.table = @table.info.id
      info.function = function
      @manager.kv.save_index(info)
      @manager.lock.synchronize do
        @table.indices[name] = Manager::Index.new(info)
      end
    end

    def get_index_status(name : String)
      index = @table.indices[name]?
      return nil if index.nil?

      ReQL::Datum.new({
        "function" => index.info.function.encode,
        "geo"      => false,
        "index"    => index.info.name,
        "multi"    => index.info.multi,
        "outdated" => false,
        "query"    => "indexCreate(#{index.info.name.inspect}, #{index.info.function.inspect})",
        "ready"    => index.info.ready,
      })
    end

    def get_all_indices_status
      ReQL::Datum.new(@table.indices.keys.map { |name| get_index_status name })
    end
  end
end
