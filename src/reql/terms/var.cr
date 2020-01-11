require "../term"

module ReQL
  class VarTerm < Term
    def inspect(io)
      io << "var_" << @args[0]
    end

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : VarTerm)
      @vars[term.args[0].as(Int64)]
    end
  end
end
