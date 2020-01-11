require "../term"

module ReQL
  class EqTerm < Term
    infix_inspect "eq"

    def check
      expect_args 2
    end
  end

  class NeTerm < Term
    infix_inspect "ne"

    def check
      expect_args 2
    end
  end

  class GtTerm < Term
    infix_inspect "gt"

    def check
      expect_args 2
    end
  end

  class GeTerm < Term
    infix_inspect "ge"

    def check
      expect_args 2
    end
  end

  class LtTerm < Term
    infix_inspect "lt"

    def check
      expect_args 2
    end
  end

  class LeTerm < Term
    infix_inspect "le"

    def check
      expect_args 2
    end
  end

  class AndTerm < Term
    infix_inspect "and"

    def check
      expect_args_at_least 1
    end
  end

  class OrTerm < Term
    infix_inspect "or"

    def check
      expect_args_at_least 1
    end
  end

  class NotTerm < Term
    infix_inspect "not"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : EqTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum == b.as_datum)
    end

    def eval_term(term : NeTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum != b.as_datum)
    end

    def eval_term(term : GtTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum > b.as_datum)
    end

    def eval_term(term : GeTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum >= b.as_datum)
    end

    def eval_term(term : LtTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum < b.as_datum)
    end

    def eval_term(term : LeTerm)
      a = eval(term.args[0])
      b = eval(term.args[1])

      Datum.new(a.as_datum <= b.as_datum)
    end

    def eval_term(term : AndTerm)
      last = Datum.new(nil)
      term.args.each do |arg|
        last = eval(arg)
        return last unless last.value
      end
      return last
    end

    def eval_term(term : OrTerm)
      last = Datum.new(nil)
      term.args.each do |arg|
        last = eval(arg)
        return last if last.value
      end
      return last
    end

    def eval_term(term : NotTerm)
      Datum.new(!eval(term.args[0]).value)
    end
  end
end
