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
      when DatumArray, DatumString
        Datum.new(target.value.size.to_i64)
      else
        raise RuntimeError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
