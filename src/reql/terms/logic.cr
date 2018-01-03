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

  class GtTerm < Term
    register_type GT
    infix_inspect "gt"

    def compile
      expect_args 2
    end
  end

  class GeTerm < Term
    register_type GE
    infix_inspect "ge"

    def compile
      expect_args 2
    end
  end

  class LtTerm < Term
    register_type LT
    infix_inspect "lt"

    def compile
      expect_args 2
    end
  end

  class LeTerm < Term
    register_type LE
    infix_inspect "le"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : EqTerm)
      a = eval term.args[0]
      b = eval term.args[1]

      Datum.wrap(a.datum == b.datum)
    end

    def eval(term : NeTerm)
      a = eval term.args[0]
      b = eval term.args[1]

      Datum.wrap(a.datum != b.datum)
    end

    def eval(term : GtTerm)
      a = eval term.args[0]
      b = eval term.args[1]

      Datum.wrap(a.datum > b.datum)
    end

    def eval(term : GeTerm)
      a = eval term.args[0]
      b = eval term.args[1]

      Datum.wrap(a.datum >= b.datum)
    end

    def eval(term : LtTerm)
      a = eval term.args[0]
      b = eval term.args[1]

      Datum.wrap(a.datum < b.datum)
    end

    def eval(term : LeTerm)
      a = eval term.args[0]
      b = eval term.args[1]

      Datum.wrap(a.datum <= b.datum)
    end
  end
end
