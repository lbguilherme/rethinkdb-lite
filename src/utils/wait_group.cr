class WaitGroup
  @pending = Atomic(Int32).new(0)
  @channel = Atomic(Channel(Nil)?).new(nil)

  def add(count : Int32 = 1) : Nil
    pending = @pending.add(count) + count

    if pending < 0
      raise "wait group has a negative number of pending jobs"
    end

    if pending == 0
      @channel.get.try &.close
    end
  end

  def done : Nil
    add(-1)
  end

  def wait : Nil
    return if @pending.get == 0
    new_ch = Channel(Nil).new
    old_ch = @channel.compare_and_set(nil, new_ch)[0]
    ch = old_ch || new_ch

    # Note that another thread might zero @pending after the first check but
    # before the channel is set. Because of this we need to check again here.
    if @pending.get == 0
      ch.close
      return
    end

    ch.receive?
  end
end
