require "./stream"

module ReQL
  class LimitStream < Stream
    def initialize(@stream : Stream, @size : Int64)

    end

    def count(max)
      @stream.count(Math.min(max, @size))
    end

    def skip(count)
      @stream.skip(count)
      @size -= count
    end

    def start_reading
      @stream.start_reading
    end

    def next_val
      if @size == 0
        return nil
      else
        @size -= 1i64
        @stream.next_val
      end
    end

    def finish_reading
      @stream.finish_reading
    end
  end
end
