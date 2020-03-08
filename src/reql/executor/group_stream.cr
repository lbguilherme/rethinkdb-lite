require "./stream"

module ReQL
  struct GroupStream < Stream
    class InternalData
      property channel = Channel(Datum?).new(16)
      property started = false
    end

    def initialize
      @internal = InternalData.new
    end

    def <<(value)
      @internal.channel.send(value)
    end

    def start_reading
      raise QueryLogicError.new "Cannot consume group stream more than once" if @internal.started
      @internal.started = true
    end

    def next_val : Datum?
      @internal.channel.receive
    end

    def finish_reading
      @internal.channel.close
    end
  end
end
