require "../term"

module ReQL
  class DoTerm < Term
    infix_inspect "do"

    def check
      expect_args_at_least 1
    end
  end

  class Evaluator
    def eval_term(term : DoTerm)
      func = eval(term.args[-1])
      args = term.args[0..-2].map { |arg| eval(arg) }
      if func.is_a? Func
        func.eval(self, args)
      else
        return func
      end
    end
  end
end
