require "json"
require "./abstract_table"

module Storage
  class KvTable < AbstractTable
    def initialize(@kv : KeyValueStore, @info : KeyValueStore::TableInfo)
    end

    def primary_key
      @info.primary_key
    end

    def insert(obj : Hash)
      key = obj[@info.primary_key].serialize

      @kv.transaction do |t|
        t.get_row(@info.id, key) do |existing_row_data|
          unless existing_row_data.nil?
            existing = ReQL::Datum.unserialize(IO::Memory.new(existing_row_data))
            duplicated_primary_key_error(existing, obj)
          end
        end

        t.set_row(@info.id, key, ReQL::Datum.new(obj).serialize)
      end
    end

    def get(key)
      @kv.get_row(@info.id, key.serialize) do |data|
        data.nil? ? nil : ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end

    def replace(key)
      key_data = key.serialize

      @kv.transaction do |t|
        existing_row_data = t.get_row(@info.id, key_data)
        if existing_row_data.nil?
          new_row = yield nil
        else
          new_row = yield ReQL::Datum.unserialize(IO::Memory.new(existing_row_data)).hash_value
        end

        t.set_row(@info.id, key, ReQL::Datum.new(new_row).serialize)
      end
    end

    def delete(key)
      key_data = key.serialize
      @kv.delete_row(@info.id, key_data)
    end

    def scan
      @kv.each_row(@info.id) do |data|
        yield ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end
  end
end
