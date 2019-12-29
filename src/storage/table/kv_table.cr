require "json"
require "./abstract_table"

module Storage
  class KvTable < AbstractTable
    def initialize(@kv : KeyValueStore, @info : KeyValueStore::TableInfo)
    end

    def primary_key
      @info.primary_key
    end

    def get(key)
      @kv.get_row(@info.id, key.serialize) do |data|
        data.nil? ? nil : ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end

    def replace(key)
      key_data = key.serialize

      @kv.transaction(@info.soft_durability) do |t|
        new_row = t.get_row(@info.id, key_data) do |existing_row_data|
          if existing_row_data.nil?
            yield nil
          else
            yield ReQL::Datum.unserialize(IO::Memory.new(existing_row_data)).hash_value
          end
        end

        t.set_row(@info.id, key_data, ReQL::Datum.new(new_row).serialize)
      end
    end

    def delete(key) : Bool
      key_data = key.serialize
      @kv.transaction(@info.soft_durability) do |t|
        if t.get_row(@info.id, key_data) { |data| data == nil }
          false
        else
          t.delete_row(@info.id, key_data)
          true
        end
      end
    end

    def scan
      @kv.each_row(@info.id) do |data|
        yield ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end
  end
end
