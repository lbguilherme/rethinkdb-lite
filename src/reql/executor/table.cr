require "./stream"

module ReQL
  class Table < Stream
    def self.reql_name
      "TABLE"
    end

    def initialize(@table : Storage::Table)
    end

    def get(key : Datum::Type)
      Row.new(@table, key)
    end

    def insert(obj : Datum::Type)
      @table.insert(obj.as(Hash))
    end

    def response
      [1]
    end
  end
end
