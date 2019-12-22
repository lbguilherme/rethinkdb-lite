require "./stream"

module ReQL
  struct LimitStream < Stream
    @stream : Box(Stream)

    def initialize(stream : Stream, @size : Int64)
      @stream = Box(Stream).new(stream)
    end

    def count(max)
      @stream.object.count(Math.min(max, @size))
    end

    def skip(count)
      @stream.object.skip(count)
      @size -= count
    end

    def start_reading
      @stream.object.start_reading
    end

    def next_val
      if @size == 0
        return nil
      else
        @size -= 1i64
        @stream.object.next_val
      end
    end

    def finish_reading
      @stream.object.finish_reading
    end
  end
end
