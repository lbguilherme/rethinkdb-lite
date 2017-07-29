require "file_utils"

FileUtils.rm_rf "test_tables"
FileUtils.mkdir_p "test_tables"

module Storage
  module TableManager
    @@tables = {} of String => Table

    def self.find(name)
      if table = @@tables[name]?
        table
      else
        @@tables[name] = Table.create("test_tables/" + name)
      end
    end
  end
end

at_exit do
  FileUtils.rm_rf "test_tables"
end
