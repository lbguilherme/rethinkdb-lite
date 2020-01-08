require "../term"

module ReQL
  class DoTerm < Term
    register_type FUNCALL
    infix_inspect "do"

    def compile
      expect_args_at_least 1
    end
  end

  class Evaluator
    def eval(term : DoTerm)
      func = eval(term.args[-1])
      args = eval(term.args[0..-2]).array_value
      if func.is_a? Func
        func.eval(self, args)
      else
        return func
      end
    end
  end
end
