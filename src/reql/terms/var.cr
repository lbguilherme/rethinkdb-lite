require "../term"

module ReQL
  class VarTerm < Term
    register_type VAR

    def inspect(io)
      io << "var_" << @args[0]
    end

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : VarTerm)
      @vars[term.args[0].as(Int64)]
    end
  end
end
