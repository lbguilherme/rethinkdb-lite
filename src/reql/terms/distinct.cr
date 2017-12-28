module ReQL
  class DistinctTerm < Term
    register_type DISTINCT
    infix_inspect "distinct"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : DistinctTerm)
      target = eval term.args[0]

      case target
      when Stream, DatumArray
        Datum.wrap(target.value.uniq)
      else
        raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
