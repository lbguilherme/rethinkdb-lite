system "rm -rf test_tables"
system "mkdir test_tables"

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
