module ReQL
  class CountTerm < Term
    register_type COUNT
    infix_inspect "count"

    def compile
      expect_args 1
    end
  end

  class Term
    def self.eval(term : CountTerm)
      target = eval term.args[0]

      case target
      when Table
        Datum.new(target.count)
      when Stream
        target.start_reading
        count = 0i64
        while tup = target.next_row
          count += 1
        end
        target.finish_reading
        Datum.new(count)
      when Datum
        Datum.new(nil)
      else
        Datum.new(nil)
      end
    end
  end
end
