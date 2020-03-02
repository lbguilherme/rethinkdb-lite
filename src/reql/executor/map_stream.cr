require "./stream"

module ReQL
  struct MapStream < Stream
    @streams : Array(Box(Stream))

    def initialize(streams : Array(Stream), @func : Array(Datum) -> Datum)
      @streams = streams.map { |stream| Box(Stream).new(stream) }
    end

    def initialize(stream : Stream, func : Datum -> Datum)
      initialize([stream], ->(vals : Array(Datum)) { func.call(vals[0]) })
    end

    def count(max)
      count = max
      @streams.each do |stream|
        count = stream.object.count(count)
      end
      count
    end

    def skip(count)
      @streams.each do |stream|
        stream.object.skip(count)
      end
    end

    def start_reading
      @streams.each do |stream|
        stream.object.start_reading
      end
    end

    def next_val
      vals = @streams.map &.object.next_val
      if vals.all? { |val| val != nil }
        @func.call(vals.map(&.not_nil!.as_datum))
      else
        nil
      end
    end

    def finish_reading
      @streams.each do |stream|
        stream.object.finish_reading
      end
    end
  end
end
