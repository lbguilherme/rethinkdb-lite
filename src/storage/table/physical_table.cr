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
      @manager.kv.get_row(@table.info.id, ReQL.encode_key(key)) do |data|
        data.nil? ? nil : ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end

    def replace(key, durability : ReQL::Durability? = nil)
      key_data = ReQL.encode_key(key)

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

            @table.indices.values.each do |index|
              update_index_data(t, index, key_data, existing_row, new_row)
            end
          end
        end
      end
    end

    def scan
      @manager.kv.each_row(@table.info.id) do |data|
        yield ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
      end
    end

    def update_index_data(t, index, key_data, old_row, new_row)
      evaluator = ReQL::Evaluator.new(@manager)
      old_computed = old_row.try { |row| index.info.function.eval(evaluator, {ReQL::Datum.new(row)}).as_datum rescue nil }
      new_computed = new_row.try { |row| index.info.function.eval(evaluator, {ReQL::Datum.new(row)}).as_datum rescue nil }

      old_set = Set(ReQL::Datum).new
      new_set = Set(ReQL::Datum).new
      if index.info.multi
        old_computed = old_computed.try &.array_value?
        old_set.concat(old_computed) if old_computed
        new_computed = new_computed.try &.array_value?
        new_set.concat(new_computed) if new_computed
      else
        old_set << old_computed if old_computed
        new_set << new_computed if new_computed
      end

      # Remove values that are now missing
      (old_set - new_set).each do |value|
        t.delete_index_entry(@table.info.id, index.info.id, ReQL.encode_key(value), key_data)
      end

      # Add new values
      (new_set - old_set).each do |value|
        t.set_index_entry(@table.info.id, index.info.id, ReQL.encode_key(value), key_data)
      end
    end

    def create_index(name : String, function : ReQL::Func, multi : Bool)
      info = KeyValueStore::IndexInfo.new
      info.name = name
      info.table = @table.info.id
      info.function = function
      info.multi = multi
      @manager.lock.synchronize do
        if @table.indices.has_key?(name)
          raise ReQL::OpFailedError.new("Index `#{name}` already exists on table `#{@table.db_name}.#{@table.info.name}`")
        end
        @manager.kv.save_index(info)
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

    def get_index_list
      ReQL::Datum.new(@table.indices.keys)
    end

    def get_all_indices_status
      ReQL::Datum.new(@table.indices.keys.map { |name| get_index_status name })
    end

    def index_scan(index_name : String, index_value_start : ReQL::Datum, index_value_end : ReQL::Datum, &block : Hash(String, ReQL::Datum) ->)
      index = @table.indices[index_name]?
      unless index
        raise ReQL::QueryLogicError.new "Index `#{index_name}` was not found on table `#{@table.db_name}.#{@table.info.name}`"
      end
      snapshot = @manager.kv.snapshot
      @manager.kv.each_index_entry(@table.info.id, index.info.id, ReQL.encode_key(index_value_start), ReQL.encode_key(index_value_end), snapshot) do |index_value_data, primary_key_data|
        @manager.kv.get_row(@table.info.id, primary_key_data, snapshot) do |row|
          yield ReQL::Datum.unserialize(IO::Memory.new(row)).hash_value if row
        end
      end
    end
  end
end
