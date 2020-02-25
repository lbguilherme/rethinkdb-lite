require "../term"

module ReQL
  class SetDifferenceTerm < Term
    infix_inspect "set_difference"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : SetDifferenceTerm)
      arr1 = eval(term.args[0]).array_value
      arr2 = eval(term.args[1]).array_value

      Datum.new((arr1 - arr2).uniq)
    end
  end
end
