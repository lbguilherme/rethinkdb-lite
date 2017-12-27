require "./stream"

module ReQL
  class FilterStream < Stream
    def initialize(@stream : Stream, @func : Datum -> Datum)
    end

    def start_reading
      @stream.start_reading
    end

    def next_val
      if val = @stream.next_val
        if @func.call(Datum.wrap(val[0])).value
          val
        else
          next_val
        end
      else
        nil
      end
    end

    def finish_reading
      @stream.finish_reading
    end
  end
end
