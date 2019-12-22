module ReQL
  abstract struct Stream < AbstractValue
    def reql_type
      "STREAM"
    end

    def value
      start_reading
      arr = [] of Datum
      while val = next_val
        arr << val
      end
      finish_reading
      arr
    end

    def count(max)
      start_reading
      count = 0i64
      while count < max && next_val
        count += 1i64
      end
      finish_reading
      count
    end

    def skip(count)
      count.times { next_val }
    end

    def each
      start_reading
      while val = next_val
        yield val
      end
      finish_reading
    end
  end
end
