require "../term"

module ReQL
  class AppendTerm < Term
    infix_inspect "append"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : AppendTerm)
      arr = eval(term.args[0]).array_value.dup
      val = eval(term.args[1]).as_datum
      arr.push(val)
      Datum.new(arr)
    end
  end
end
