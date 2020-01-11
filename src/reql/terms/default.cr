require "../term"

module ReQL
  class DefaultTerm < Term
    infix_inspect "default"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : DefaultTerm)
      base = begin
        eval(term.args[0])
      rescue ex : NonExistenceError | UserError
        Datum.new(nil)
      end

      if base.is_a? Datum && !base.value
        eval(term.args[1])
      else
        base
      end
    end
  end
end
