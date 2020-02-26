require "../term"

module ReQL
  class DistinctTerm < Term
    infix_inspect "distinct"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : DistinctTerm)
      target = eval(term.args[0])

      if array = target.array_or_set_value?
        Datum.new(array.to_set)
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
