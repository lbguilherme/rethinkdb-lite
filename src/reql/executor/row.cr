require "./abstract_value"

module ReQL
  abstract struct Row < AbstractValue
    def reql_type
      "ROW"
    end

    def initialize(@table : Storage::AbstractTable)
    end

    def as_row
      self
    end

    abstract def key : Datum

    def table : Storage::AbstractTable
      @table
    end
  end
end
