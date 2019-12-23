require "./stream"

module ReQL
  struct MapStream < Stream
    @stream : Box(Stream)

    def initialize(stream : Stream, @func : Datum -> Datum)
      @stream = Box(Stream).new(stream)
    end

    def count(max)
      @stream.object.count(max)
    end

    def skip(count)
      @stream.object.skip(count)
    end

    def start_reading
      @stream.object.start_reading
    end

    def next_val
      if val = @stream.object.next_val
        @func.call(val)
      else
        nil
      end
    end

    def finish_reading
      @stream.object.finish_reading
    end
  end
end
