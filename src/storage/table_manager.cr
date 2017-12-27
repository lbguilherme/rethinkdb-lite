require "file_utils"
require "./table/*"
require "./config"

module Storage
  module TableManager
    @@tables = {} of String => AbstractTable

    def self.load_all
      Config.databases.each do |db|
        db.tables.each do |tbl|
          @@tables[tbl.id] = StoredTable.open(File.join(Config.data_path, tbl.id))
        end
      end

      create_db("test")
    end

    def self.find_table(db_name, table_name) : AbstractTable?
      id = Config.databases.find { |db| db.name == db_name }.try &.tables.find { |table| table.name == table_name }.try &.id
      id ? @@tables[id] : nil
    end

    def self.create_db(db_name)
      if db_name == "rethinkdb" || Config.databases.find { |db| db.name == db_name }
        raise ReQL::OpFailedError.new("Database `#{db_name}` already exists")
      end
      Config.databases << Config::Database.new(
        UUID.random.to_s,
        db_name,
        [] of Config::Table
      )
      Config.save
    end

    def self.create_table(db_name, table_name)
      db = Config.databases.find { |db| db.name == db_name }
      unless db
        raise "db doesnt exists"
      end
      if db.tables.find { |table| table.name == table_name }
        raise "table already exists"
      end

      FileUtils.mkdir_p Config.data_path
      id = UUID.random.to_s
      @@tables[id] = StoredTable.create(File.join(Config.data_path, id))

      Config.databases.find { |db| db.name == db_name }.not_nil!.tables << Config::Table.new(id, table_name)
      Config.save
    end

    def self.close_all
      @@tables.each_value &.close
      @@tables = {} of String => AbstractTable
    end
  end
end

Storage::TableManager.load_all
at_exit { Storage::TableManager.close_all }
