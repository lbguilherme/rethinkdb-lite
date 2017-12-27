require "./datum"

module ReQL
  class Row < Datum
    def self.reql_name
      "ROW"
    end

    def initialize(@table : Storage::AbstractTable, @key : Datum::Type)
    end

    def value
      @table.get(@key)
    end
  end
end
