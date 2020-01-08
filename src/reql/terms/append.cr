require "../term"

module ReQL
  class AppendTerm < Term
    register_type APPEND
    infix_inspect "append"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : AppendTerm)
      arr = eval(term.args[0]).array_value.dup
      val = eval(term.args[1]).as_datum
      arr.push(val)
      Datum.new(arr)
    end
  end
end
