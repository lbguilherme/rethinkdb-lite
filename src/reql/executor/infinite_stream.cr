require "./stream"

module ReQL
  abstract class InfiniteStream < Stream
    def self.reql_name
      "STREAM"
    end

    private def err
      raise QueryLogicError.new "Cannot use an infinite stream with an aggregation function (`reduce`, `count`, etc.) or coerce it to an array."
    end

    def to_datum_array
      err
    end

    def value
      err
    end

    def count(max)
      err
    end
  end
end
