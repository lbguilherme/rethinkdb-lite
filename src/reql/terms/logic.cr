module ReQL
  class EqTerm < Term
    register_type EQ
    infix_inspect "eq"

    def compile
      expect_args 2
    end
  end

  class NeTerm < Term
    register_type NE
    infix_inspect "ne"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : EqTerm)
      a = eval term.args[0]
      b = eval term.args[1]

      Datum.wrap(a.value == b.value)
    end

    def eval(term : NeTerm)
      a = eval term.args[0]
      b = eval term.args[1]

      Datum.wrap(a.value != b.value)
    end
  end
end
