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

  class AndTerm < Term
    register_type AND
    infix_inspect "and"

    def compile
      expect_args_at_least 1
    end
  end

  class OrTerm < Term
    register_type OR
    infix_inspect "or"

    def compile
      expect_args_at_least 1
    end
  end

  class NotTerm < Term
    register_type NOT
    infix_inspect "not"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : EqTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum == b.as_datum)
    end

    def eval(term : NeTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum != b.as_datum)
    end

    def eval(term : GtTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum > b.as_datum)
    end

    def eval(term : GeTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum >= b.as_datum)
    end

    def eval(term : LtTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum < b.as_datum)
    end

    def eval(term : LeTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum <= b.as_datum)
    end

    def eval(term : AndTerm)
      last = Datum.new(nil)
      term.args.each do |arg|
        last = eval(arg)
        return last unless last.value
      end
      return last
    end

    def eval(term : OrTerm)
      last = Datum.new(nil)
      term.args.each do |arg|
        last = eval(arg)
        return last if last.value
      end
      return last
    end

    def eval(term : NotTerm)
      Datum.new(!eval(term.args[0]).value)
    end
  end
end
