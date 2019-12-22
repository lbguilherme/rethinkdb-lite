require "./stream"

module ReQL
  abstract struct InfiniteStream < Stream
    def reql_type
      "STREAM"
    end

    private def err
      raise QueryLogicError.new "Cannot use an infinite stream with an aggregation function (`reduce`, `count`, etc.) or coerce it to an array."
    end

    def value
      err
    end

    def count(max)
      err
    end
  end
end
