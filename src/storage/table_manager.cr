require "file_utils"

FileUtils.mkdir_p "/tmp/rethinkdb-lite/test_tables"

module Storage
  module TableManager
    @@tables = {} of String => Table

    def self.find(name)
      if table = @@tables[name]?
        table
      else
        @@tables[name] = Table.create("/tmp/rethinkdb-lite/test_tables/" + name)
      end
    end
  end
end
