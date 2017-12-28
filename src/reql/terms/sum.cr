module ReQL
  class SumTerm < Term
    register_type SUM
    infix_inspect "sum"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : SumTerm)
      target = eval term.args[0]

      sum = 0i64
      case target
      when Stream
        target.start_reading
        while tup = target.next_val
          x = Datum.wrap(tup[0])
          expect_type x, DatumNumber
          sum += x.value
        end
        target.finish_reading
      when DatumArray
        target.value.each do |x|
          x = Datum.wrap(x)
          expect_type x, DatumNumber
          sum += x.value
        end
      else
        raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end

      Datum.wrap(sum)
    end
  end
end
