require "./stream"

module ReQL
  class Range < Stream
    def initialize(@from : Int64, @to : Int64?)
      @value = 0i64
    end

    def start_reading
      @value = @from - 1
    end

    def next_row
      if @value == @to
        return nil
      else
        @value += 1
        return {@value}
      end
    end

    def finish_reading
    end
  end
end
