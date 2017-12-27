require "file_utils"
require "./table/*"

FileUtils.rm_rf "/tmp/rethinkdb-lite/data/"

module Storage
  module TableManager
    @@tables = {} of String => Hash(String, AbstractTable)
    class_property data_path : String = "/tmp/rethinkdb-lite/data/"

    def self.load_all
      FileUtils.mkdir_p @@data_path
      Dir.new(@@data_path).each_child do |child|
        next unless child =~ /([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\.dat/
        db_name = $1
        table_name = $2

        unless @@tables[db_name]?
          @@tables[db_name] = Hash(String, AbstractTable).new
        end

        @@tables[db_name][table_name] = StoredTable.open(File.join(@@data_path, "#{db_name}.#{table_name}"))
      end

      if @@tables.size == 0
        @@tables["test"] = Hash(String, AbstractTable).new
      end
    end

    def self.find(db_name, table_name) : AbstractTable?
      @@tables[db_name]?.try &.[table_name]?
    end

    def self.create(db_name, table_name) : AbstractTable
      FileUtils.mkdir_p @@data_path
      name = "#{db_name}.#{table_name}"
      path = File.join(@@data_path, name)
      unless @@tables[db_name]?
        @@tables[db_name] = Hash(String, AbstractTable).new
      end
      @@tables[db_name][table_name] = StoredTable.create(path)
    end

    def self.close_all
      @@tables.each_value &.each_value &.close
      @@tables = {} of String => Hash(String, AbstractTable)
    end
  end
end

Storage::TableManager.load_all
at_exit { Storage::TableManager.close_all }
