require "./stream"

module ReQL
  class MapStream < Stream
    def initialize(@stream : Stream, @func : Datum -> Datum)

    end

    def count
      @stream.count
    end

    def start_reading
      @stream.start_reading
    end

    def next_val
      if val = @stream.next_val
        {@func.call(Datum.wrap(val[0])).value}
      else
        nil
      end
    end

    def finish_reading
      @stream.finish_reading
    end
  end
end
