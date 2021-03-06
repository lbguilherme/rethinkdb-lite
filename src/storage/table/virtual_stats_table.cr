require "./virtual_table"

module Storage
  struct VirtualStatsTable < VirtualTable
    def initialize(manager : Manager)
      super("stats", manager)
    end

    def get_cluster
      ReQL::Datum.new({
        "id"           => ["cluster"],
        "query_engine" => {
          "client_connections" => 0,
          "clients_active"     => 0,
          "queries_per_sec"    => 0,
          "read_docs_per_sec"  => @manager.lock.synchronize do
            @manager.table_by_id.values.map(&.impl.read_docs_on_table.per_second).sum
          end,
          "written_docs_per_sec" => @manager.lock.synchronize do
            @manager.table_by_id.values.map(&.impl.written_docs_on_table.per_second).sum
          end,
        },
      }).hash_value
    end

    def get_server
      ReQL::Datum.new({
        "id" => [
          "server",
          @manager.system_info.id.to_s,
        ],
        "query_engine" => {
          "client_connections" => 0,
          "clients_active"     => 0,
          "queries_per_sec"    => 0,
          "queries_total"      => 0,
          "read_docs_per_sec"  => @manager.lock.synchronize do
            @manager.table_by_id.values.map(&.impl.read_docs_on_table.per_second).sum
          end,
          "read_docs_total" => @manager.lock.synchronize do
            @manager.table_by_id.values.map(&.impl.read_docs_on_table.total).sum
          end,
          "written_docs_per_sec" => @manager.lock.synchronize do
            @manager.table_by_id.values.map(&.impl.written_docs_on_table.per_second).sum
          end,
          "written_docs_total" => @manager.lock.synchronize do
            @manager.table_by_id.values.map(&.impl.written_docs_on_table.total).sum
          end,
        },
        "server" => @manager.system_info.name,
      }).hash_value
    end

    def get_table(info : KeyValueStore::TableInfo)
      table_impl = @manager.lock.synchronize { @manager.table_by_id[info.id]?.try &.impl }
      ReQL::Datum.new({
        "id" => [
          "table",
          info.id.to_s,
        ],
        "query_engine" => {
          "read_docs_per_sec"    => table_impl.try &.read_docs_on_table.per_second || 0,
          "written_docs_per_sec" => table_impl.try &.written_docs_on_table.per_second || 0,
        },
        "db"    => @manager.lock.synchronize { @manager.database_by_id[info.db]?.try &.info.name || info.db.to_s },
        "table" => info.name,
      }).hash_value
    end

    def get_table_server(info : KeyValueStore::TableInfo)
      table_impl = @manager.lock.synchronize { @manager.table_by_id[info.id]?.try &.impl }
      ReQL::Datum.new({
        "id" => [
          "table_server",
          info.id.to_s,
          @manager.system_info.id.to_s,
        ],
        "query_engine" => {
          "read_docs_per_sec"    => table_impl.try &.read_docs_on_table.per_second || 0,
          "read_docs_total"      => table_impl.try &.read_docs_on_table.total || 0,
          "written_docs_per_sec" => table_impl.try &.written_docs_on_table.per_second || 0,
          "written_docs_total"   => table_impl.try &.written_docs_on_table.total || 0,
        },
        "server"         => @manager.system_info.name,
        "storage_engine" => {
          "cache" => {
            "in_use_bytes" => 0,
          },
          "disk" => {
            "read_bytes_per_sec" => 0,
            "read_bytes_total"   => 0,
            "space_usage"        => {
              "data_bytes"         => 0,
              "garbage_bytes"      => 0,
              "metadata_bytes"     => 0,
              "preallocated_bytes" => 0,
            },
            "written_bytes_per_sec" => 0,
            "written_bytes_total"   => 0,
          },
        },
        "db"    => @manager.lock.synchronize { @manager.database_by_id[info.db]?.try &.info.name || info.db.to_s },
        "table" => info.name,
      }).hash_value
    end

    def get(key)
      array = key.array_value?
      return nil unless array

      if array.size == 1 && array[0] == "cluster"
        return get_cluster
      end

      if array.size == 2 && array[0] == "server" && array[1] == @manager.system_info.id.to_s
        return get_server
      end

      if array.size == 2 && array[0] == "table"
        id = UUID.new(array[1].string_value) rescue return nil
        info = @manager.kv.get_table(id)
        return info ? get_table(info) : nil
      end

      if array.size == 3 && array[0] == "table_server" && array[2] == @manager.system_info.id.to_s
        id = UUID.new(array[1].string_value) rescue return nil
        info = @manager.kv.get_table(id)
        return info ? get_table_server(info) : nil
      end

      nil
    end

    def scan
      yield get_cluster
      yield get_server
      @manager.kv.each_table do |info|
        yield get_table(info)
        yield get_table_server(info)
      end
    end
  end
end
