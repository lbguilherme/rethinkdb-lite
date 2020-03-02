require "./virtual_table"

module Storage
  struct VirtualServerStatusTable < VirtualTable
    def initialize(manager : Manager)
      super("server_status", manager)
    end

    private def encode(info : KeyValueStore::SystemInfo)
      ReQL::Datum.new({
        "id"      => @manager.system_info.id.to_s,
        "name"    => @manager.system_info.name,
        "process" => {
          "argv"          => ARGV,
          "pid"           => Process.pid,
          "cache_size_mb" => 1024,
          "version"       => "dev",
          "time_started"  => @manager.start_time,

        },
        "network" => {
          "canonical_addresses" => [] of String,
          "cluster_port"        => 0,
          "http_admin_port"     => 0,
          "reql_port"           => 0,
          "connected_to"        => {} of String => String,
          "hostname"            => System.hostname,
          "time_connected"      => @manager.start_time,
        },
      }).hash_value
    end

    def get(key)
      info = @manager.system_info
      id = UUID.new(key.string_value) rescue return nil
      encode(info.id == id ? info : nil)
    end

    def scan
      yield encode(@manager.system_info)
    end
  end
end
