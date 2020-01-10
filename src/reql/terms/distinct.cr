require "../term"

module ReQL
  class DistinctTerm < Term
    infix_inspect "distinct"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : DistinctTerm)
      target = eval(term.args[0])

      if array = target.array_value?
        Datum.new(array.uniq)
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
