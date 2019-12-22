require "file_utils"
require "./table/*"

module Storage
  class Config
    VERSION = 1

    property data_path : String
    property databases = [] of DatabaseInfo
    property server_info = ServerInfo.new("", "")

    record DatabaseInfo,
      id : String,
      name : String,
      tables : Array(TableInfo)

    record TableInfo,
      id : String,
      name : String

    record ServerInfo,
      id : String,
      name : String

    def initialize(@data_path)
      load
    end

    private def config_table
      FileUtils.mkdir_p @data_path
      if File.exists?(File.join(@data_path, "config.dat"))
        StoredTable.open(File.join(@data_path, "config"))
      else
        StoredTable.create(File.join(@data_path, "config"))
      end
    end

    def load
      table = config_table
      data = table.get("config")
      version = data.try &.["version"].try &.int64_value.to_i32
      table.close
      case version
      when nil
        load_v0 data
      when 1
        load_v1 data.not_nil!
      else
        raise "Read config version from a future version. Don't know how to read it."
      end

      save if version != VERSION
    end

    def save
      table = config_table
      table.replace("config") { {
        "id"        => "config",
        "version"   => VERSION,
        "databases" => @databases.map { |db| {
          "id"     => db.id,
          "name"   => db.name,
          "tables" => db.tables.map { |tbl| {
            "id"   => tbl.id,
            "name" => tbl.name,
          } },
        } },
        "server_info" => {
          "id"   => @server_info.id,
          "name" => @server_info.name,
        },
      } }
      data = table.get("config")
      table.close
    end

    private def load_v0(data)
      @databases = [] of DatabaseInfo
      @server_info = ServerInfo.new(UUID.random.to_s, initial_server_name)
    end

    private def load_v1(data)
      @databases = data["databases"].array_value.map { |x|
        DatabaseInfo.new(
          x.hash_value["id"].string_value,
          x.hash_value["name"].string_value,
          x.hash_value["tables"].array_value.map { |x|
            TableInfo.new(
              x.hash_value["id"].string_value,
              x.hash_value["name"].string_value,
            )
          },
        )
      }
      @server_info = ServerInfo.new(
        data["server_info"].hash_value["id"].string_value,
        data["server_info"].hash_value["name"].string_value
      )
    end

    private def initial_server_name
      hostname = File.read("/etc/hostname").strip.gsub(/[^A-Za-z0-9_]/, "_")
      alphabet = ("A".."Z").to_a + ("a".."z").to_a + ("1".."0").to_a
      hostname + "_" + (0...3).map { alphabet.sample }.join
    end
  end
end
