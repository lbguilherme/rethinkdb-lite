require "./stream"

module ReQL
  struct Db < AbstractValue
    getter name

    def reql_type
      "DATABASE"
    end

    def initialize(@name : String)
    end

    def value : Type
      raise QueryLogicError.new "Query result must be of type DATUM, GROUPED_DATA, or STREAM (got DATABASE)"
    end

    def as_database
      self
    end

    def as_datum
      raise QueryLogicError.new("Expected type DATUM but found DATABASE.")
    end
  end
end
