module ReQL
  class CountTerm < Term
    register_type COUNT
    infix_inspect "count"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : CountTerm)
      target = eval term.args[0]

      case target
      when Stream
        Datum.wrap(target.count(Int32::MAX.to_i64))
      when DatumArray, DatumString
        Datum.wrap(target.value.size.to_i64)
      else
        raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
