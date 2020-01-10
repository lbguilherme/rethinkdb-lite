require "../term"

module ReQL
  class UpcaseTerm < Term
    infix_inspect "upcase"

    def check
      expect_args 1
    end
  end

  class DowncaseTerm < Term
    infix_inspect "downcase"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : UpcaseTerm)
      target = eval(term.args[0]).string_value
      Datum.new(target.upcase)
    end

    def eval(term : DowncaseTerm)
      target = eval(term.args[0]).string_value
      Datum.new(target.downcase)
    end
  end
end
