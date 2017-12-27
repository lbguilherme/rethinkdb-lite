require "file_utils"

FileUtils.rm_rf "/tmp/rethinkdb-lite/data/"

module Storage
  module TableManager
    @@tables = {} of String => Table
    class_property data_path : String = "/tmp/rethinkdb-lite/data/"

    def self.find(db_name, table_name) : Table
      name = "#{db_name}.#{table_name}"
      if table = @@tables[name]?
        return table
      end

      FileUtils.mkdir_p @@data_path
      path = File.join(@@data_path, name)

      if File.exists? path
        @@tables[name] = Table.open(path)
      else
        @@tables[name] = Table.create(path)
      end
    end

    def self.create(db_name, table_name) : Table
      FileUtils.mkdir_p @@data_path
      name = "#{db_name}.#{table_name}"
      path = File.join(@@data_path, name)
      @@tables[name] = Table.create(path)
    end
  end
end
