require "./stream"

module ReQL
  class SkipStream < Stream
    def initialize(@stream : Stream, @skip : Int64)
    end

    def count(max)
      Math.max(0i64, @stream.count(max + @skip) - @skip)
    end

    def skip(count)
      @stream.skip(count)
    end

    def start_reading
      @stream.start_reading
      @stream.skip(@skip)
    end

    def next_val
      @stream.next_val
    end

    def finish_reading
      @stream.finish_reading
    end
  end
end
