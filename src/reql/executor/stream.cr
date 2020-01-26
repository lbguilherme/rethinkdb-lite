require "./abstract_value"

module ReQL
  abstract struct Stream < AbstractValue
    def reql_type
      "STREAM"
    end

    def value : Type
      start_reading
      begin
        arr = [] of Datum
        while val = next_val
          arr << val.as_datum
        end
        arr
      ensure
        finish_reading
      end
    end

    def count(max)
      start_reading
      begin
        count = 0i64
        while count < max && next_val
          count += 1i64
        end
        count
      ensure
        finish_reading
      end
    end

    def skip(count)
      count.times { next_val }
    end

    def each
      start_reading
      begin
        while val = next_val
          yield val
        end
      ensure
        finish_reading
      end
    end
  end
end
