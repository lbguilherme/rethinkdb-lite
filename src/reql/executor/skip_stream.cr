require "./stream"

module ReQL
  struct SkipStream < Stream
    @stream : Box(Stream)

    def initialize(stream : Stream, @skip : Int64)
      @stream = Box(Stream).new(stream)
    end

    def count(max)
      Math.max(0i64, @stream.object.count(max + @skip) - @skip)
    end

    def skip(count)
      @stream.object.skip(count)
    end

    def start_reading
      @stream.object.start_reading
      @stream.object.skip(@skip)
    end

    def next_val
      @stream.object.next_val
    end

    def finish_reading
      @stream.object.finish_reading
    end
  end
end
