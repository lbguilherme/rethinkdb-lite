require "../term"

module ReQL
  class UpCaseTerm < Term
    register_type UPCASE
    infix_inspect "upcase"

    def compile
      expect_args 1
    end
  end

  class DownCaseTerm < Term
    register_type DOWNCASE
    infix_inspect "downcase"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : UpCaseTerm)
      target = eval(term.args[0]).string_value
      Datum.new(target.upcase)
    end

    def eval(term : DownCaseTerm)
      target = eval(term.args[0]).string_value
      Datum.new(target.downcase)
    end
  end
end
