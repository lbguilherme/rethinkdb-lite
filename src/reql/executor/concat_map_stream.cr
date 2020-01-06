require "./stream"

module ReQL
  struct ConcatMapStream < Stream
    @stream : Box(Stream)
    @current : Iterator(Datum) | Nil = nil

    def initialize(stream : Stream, @func : Datum -> Datum)
      @stream = Box(Stream).new(stream)
    end

    # def count(max)
    #   @stream.object.count(max)
    # end

    def start_reading
      @stream.object.start_reading
    end

    def next_val
      case current = @current
      when Iterator(Datum)
        val = current.next
        if val.is_a? Iterator::Stop
          @current = nil
          next_val
        else
          val
        end
      else
        if val = @stream.object.next_val
          @current = @func.call(val.as_datum).array_value.each
          next_val
        else
          nil
        end
      end
    end

    def finish_reading
      @stream.object.finish_reading
    end
  end
end
