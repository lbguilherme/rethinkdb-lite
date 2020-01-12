class WaitGroup
  @pending = Atomic(Int64).new(0i64)
  @channel = Atomic(Channel(Nil)?).new(nil)

  def add : Nil
    @pending.add(1i64)
  end

  def done : Nil
    pending = @pending.sub(1i64) - 1i64
    if pending < 0i64
      raise "finished more times than started"
    end

    if pending == 0i64
      @channel.get.try &.close
    end
  end

  def wait : Nil
    return if @pending.get == 0i64
    ch = @channel.set(Channel(Nil).new)

    if @pending.get == 0i64
      ch.close
      return
    end

    ch.receive?
  end
end
