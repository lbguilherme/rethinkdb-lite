require "./abstract_table"
require "../metrics"

module Storage
  struct PhysicalTable < AbstractTable
    MUTEX_SHARDS = 2 << 12
    @@mutexes : Array(Mutex) = (0...MUTEX_SHARDS).map { Mutex.new }

    property read_docs_on_table = PerSecondMetric.new
    property written_docs_on_table = PerSecondMetric.new

    def initialize(@manager : Manager, @table : Manager::Table)
    end

    def primary_key
      @table.info.primary_key
    end

    def get(key)
      @read_docs_on_table.add(1)
      @manager.kv.get_row(@table.info.id, ReQL.encode_key(key)) do |data|
        if data
          hash = ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
          hash[primary_key] = key
          hash
        end
      end
    end

    def replace(key, durability : ReQL::Durability? = nil)
      key_data = ReQL.encode_key(key)

      @@mutexes[key.hash % MUTEX_SHARDS].synchronize do
        existing_row = @manager.kv.get_row(@table.info.id, key_data) do |existing_row_data|
          if existing_row_data.nil?
            nil
          else
            hash = ReQL::Datum.unserialize(IO::Memory.new(existing_row_data)).hash_value
            hash[primary_key] = key
            hash
          end
        end

        new_row = yield existing_row

        if new_row.nil?
          unless existing_row.nil?
            @written_docs_on_table.add(1)

            if @table.indices.empty?
              @manager.kv.delete_row(@table.info.id, key_data, durability || @table.info.durability)
            else
              batch = @manager.kv.create_batch
              batch.delete_row(@table.info.id, key_data)

              # TODO: This crashes the compiler
              # @table.indices.values.each do |index|
              #   update_index_data(batch, index, key_data, existing_row, new_row)
              # end

              @manager.kv.write_batch(batch, durability || @table.info.durability)
            end
          end
        else
          if existing_row != new_row
            @written_docs_on_table.add(1)

            if @table.indices.empty?
              @manager.kv.set_row(@table.info.id, key_data, ReQL::Datum.new(new_row).serialize, durability || @table.info.durability)
            else
              batch = @manager.kv.create_batch

              new_row.delete(primary_key)
              batch.set_row(@table.info.id, key_data, ReQL::Datum.new(new_row).serialize)
              new_row[primary_key] = key

              @table.indices.values.each do |index|
                update_index_data(batch, index, key_data, existing_row, new_row)
              end

              @manager.kv.write_batch(batch, durability || @table.info.durability)
            end
          end
        end
      end
    end

    def scan
      @manager.kv.each_row(@table.info.id) do |key, data|
        @read_docs_on_table.add(1)
        hash = ReQL::Datum.unserialize(IO::Memory.new(data)).hash_value
        hash[primary_key] = ReQL.decode_key(key)
        yield hash
      end
    end

    private def index_values(evaluator, index, row)
      computed = row.try { |row| index.info.function.eval(evaluator, {ReQL::Datum.new(row)}).as_datum rescue nil }

      if computed.nil?
        return Set({ReQL::Datum, Int32}).new
      end

      if index.info.multi
        set = Set({ReQL::Datum, Int32}).new
        hash = Hash(ReQL::Datum, Int32).new { 0 }
        computed.array_or_set_value?.try &.each do |val|
          set << {val, hash[val] += 1}
        end

        set
      else
        [{computed, 1}].to_set
      end
    end

    def update_index_data(t, index, key_data, old_row, new_row)
      evaluator = ReQL::Evaluator.new(@manager)

      old_values = index_values(evaluator, index, old_row)
      new_values = index_values(evaluator, index, new_row)

      # Remove values that are now missing
      (old_values - new_values).each do |(value, counter)|
        @written_docs_on_table.add(1)
        t.delete_index_entry(@table.info.id, index.info.id, ReQL.encode_key(value), counter, key_data)
      end

      # Add new values
      (new_values - old_values).each do |(value, counter)|
        @written_docs_on_table.add(1)
        t.set_index_entry(@table.info.id, index.info.id, ReQL.encode_key(value), counter, key_data)
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
        @read_docs_on_table.add(2)
        @manager.kv.get_row(@table.info.id, primary_key_data, snapshot) do |row|
          yield ReQL::Datum.unserialize(IO::Memory.new(row)).hash_value if row
        end
      end
    end
  end
end
