require "./stream"

module ReQL
  class Range < Stream
    def initialize(@from : Int64, @to : Int64)
      @value = 0i64
    end

    def count
      @to - @from
    end

    def start_reading
      @value = @from
    end

    def next_val
      if @value == @to
        return nil
      else
        v = @value
        @value += 1
        return {v}
      end
    end

    def finish_reading
    end
  end
end
