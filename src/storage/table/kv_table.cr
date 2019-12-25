require "json"
require "./abstract_table"

module Storage
  class KvTable < AbstractTable
    def initialize(@kv : KeyValueStore, @info : KeyValueStore::TableInfo)
    end

    def insert(obj : Hash)
      key = obj[@info.primary_key].serialize

      @kv.data_transaction do |t|
        existing_row_data = t.get_row(@info.id, key)
        unless existing_row_data.nil?
          row = ReQL::Datum.unserialize(IO::Memory.new(existing_row_data))
          pretty_row = JSON.build(4) { |builder| ReQL::Datum.new(row).to_json(builder) }
          pretty_obj = JSON.build(4) { |builder| ReQL::Datum.new(obj).to_json(builder) }
          raise ReQL::OpFailedError.new("Duplicate primary key `id`:\n#{pretty_row}\n#{pretty_obj}")
        end

        t.set_row(@info.id, key, ReQL::Datum.new(obj).serialize)
      end
    end

    def get(key)
      data = @kv.get_row(@info.id, key.serialize)
      data.nil? ? nil : ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
    end

    def replace(key)
      key_data = key.serialize

      @kv.data_transaction do |t|
        existing_row_data = t.get_row(@info.id, key_data)
        if existing_row_data.nil?
          new_row = yield nil
        else
          new_row = yield ReQL::Datum.unserialize(IO::Memory.new(existing_row_data)).hash_value
        end

        t.set_row(@info.id, key, ReQL::Datum.new(new_row).serialize)
      end
    end

    def scan
      @kv.each_row(@info.id) do |data|
        yield ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end
  end
end
