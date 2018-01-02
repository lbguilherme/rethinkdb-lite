require "file_utils"
require "./table/*"
require "./config"

module Storage
  class TableManager
    @tables = {} of String => AbstractTable

    def initialize(@config : Config)
      load_all
    end

    def load_all
      @config.databases.each do |db|
        db.tables.each do |tbl|
          @tables[tbl.id] = StoredTable.open(File.join(@config.data_path, tbl.id))
        end
      end

      create_db("test")
    end

    def find_table(db_name, table_name) : AbstractTable?
      if db_name == "rethinkdb"
        case table_name
        when "db_config"
          return VirtualDbConfigTable.new(@config)
        when "table_status"
          return VirtualTableConfigTable.new(@config)
        else
          return nil
        end
      end

      id = @config.databases.find { |db| db.name == db_name }.try &.tables.find { |table| table.name == table_name }.try &.id
      id ? @tables[id] : nil
    end

    def create_db(db_name)
      if db_name == "rethinkdb" || @config.databases.find { |db| db.name == db_name }
        raise ReQL::OpFailedError.new("Database `#{db_name}` already exists")
      end
      @config.databases << Config::DatabaseInfo.new(
        UUID.random.to_s,
        db_name,
        [] of Config::TableInfo
      )
      @config.save
    end

    def create_table(db_name, table_name)
      db = @config.databases.find { |db| db.name == db_name }
      unless db
        raise "db doesnt exists"
      end
      if db.tables.find { |table| table.name == table_name }
        raise "table already exists"
      end

      FileUtils.mkdir_p @config.data_path
      id = UUID.random.to_s
      @tables[id] = StoredTable.create(File.join(@config.data_path, id))

      @config.databases.find { |db| db.name == db_name }.not_nil!.tables << Config::TableInfo.new(id, table_name)
      @config.save
    end

    def close_all
      @tables.each_value &.close
      @tables = {} of String => AbstractTable
    end
  end
end
