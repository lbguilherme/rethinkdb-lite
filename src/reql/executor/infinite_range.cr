require "./infinite_stream"

module ReQL
  class InfiniteRange < InfiniteStream
    def initialize
      @value = 0i64
    end

    def start_reading
      @value = 0i64
    end

    def next_val
      v = @value
      @value += 1
      return {v}
    end

    def finish_reading
    end
  end
end
