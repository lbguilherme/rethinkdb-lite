require "file_utils"

FileUtils.rm_rf "/tmp/rethinkdb-lite/tables/"
FileUtils.mkdir_p "/tmp/rethinkdb-lite/tables/"

module Storage
  module TableManager
    @@tables = {} of String => Table

    def self.find(name)
      if table = @@tables[name]?
        table
      else
        @@tables[name] = Table.create("/tmp/rethinkdb-lite/tables/" + name)
      end
    end
  end
end
