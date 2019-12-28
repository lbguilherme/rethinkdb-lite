require "./stream"

module ReQL
  struct FilterStream < Stream
    @stream : Box(Stream)

    def initialize(stream : Stream, @func : Datum -> Datum)
      @stream = Box(Stream).new(stream)
    end

    def start_reading
      @stream.object.start_reading
    end

    def next_val
      if val = @stream.object.next_val
        if @func.call(val.as_datum).value
          val
        else
          next_val
        end
      else
        nil
      end
    end

    def finish_reading
      @stream.object.finish_reading
    end
  end
end
