require "file_utils"
require "./table/*"

module Storage
  module Config
    VERSION = 1

    class_property data_path : String = "/tmp/rethinkdb-lite/data/"
    class_property databases = [] of Database

    record Database,
      id : String,
      name : String,
      tables : Array(Table)

    record Table,
      id : String,
      name : String

    private def self.config_table
      FileUtils.mkdir_p @@data_path
      if File.exists?(File.join(@@data_path, "config.dat"))
        StoredTable.open(File.join(@@data_path, "config"))
      else
        StoredTable.create(File.join(@@data_path, "config"))
      end
    end

    def self.load
      table = config_table
      data = table.get("config")
      version = data.try &.["version"].try &.as(Int32)
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

    def self.save
      table = config_table
      table.replace("config") { {
        "id"        => "config",
        "version"   => VERSION,
        "databases" => @@databases.map { |db| {
          "id"     => db.id,
          "name"   => db.name,
          "tables" => db.tables.map { |tbl| {
            "id"   => tbl.id,
            "name" => tbl.name,
          } },
        } },
      } }
      data = table.get("config")
      table.close
    end

    private def self.load_v0(data)
      @@databases = [] of Database
    end

    private def self.load_v1(data)
      @@databases = data["databases"].as(Array).map { |x|
        Database.new(
          x.as(Hash)["id"].as(String),
          x.as(Hash)["name"].as(String),
          x.as(Hash)["tables"].as(Array).map { |x|
            Table.new(
              x.as(Hash)["id"].as(String),
              x.as(Hash)["name"].as(String),
            )
          },
        )
      }
    end
  end
end

FileUtils.rm_rf Storage::Config.data_path

Storage::Config.load
