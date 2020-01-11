class PerSecondMetric
  @current = Atomic(UInt64).new(0u64)
  @previous = Atomic(UInt64).new(0u64)
  @delta_nanoseconds = Atomic(UInt64).new(0u64)
  @total = Atomic(UInt64).new(0u64)
  @last_timer = Time.monotonic
  @finished = false

  def initialize
    spawn do
      until @finished
        sleep 1

        current = @current.swap(0u64)
        @previous.set(current)
        @total.add(current)
        timer = Time.monotonic
        @delta_nanoseconds.set((timer - @last_timer).total_nanoseconds.to_u64)
        @last_timer = timer
      end
    end
  end

  def add(value : Int)
    @current.add(value.to_u64)
  end

  def per_second
    (@previous.get / @delta_nanoseconds.get * Time::NANOSECONDS_PER_SECOND).ceil
  end

  def total
    @total.get
  end

  def close
    @finished = true
  end
end
