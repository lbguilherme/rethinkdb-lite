require "./stream"

module ReQL
  struct ArrayStream < Stream
    def initialize(@array : Array(Datum))
      @index = 0
    end

    def count(max)
      Math.max(@array.size, max)
    end

    def skip(count)
      @index += count
    end

    def start_reading
      @index = 0
    end

    def next_val
      if @index < @array.size
        val = @array[@index]
        @index += 1
        val
      else
        nil
      end
    end

    def finish_reading
    end
  end
end
