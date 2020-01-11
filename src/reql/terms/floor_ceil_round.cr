require "../term"

module ReQL
  class FloorTerm < Term
    infix_inspect "floor"

    def check
      expect_args 1
    end
  end

  class CeilTerm < Term
    infix_inspect "ceil"

    def check
      expect_args 1
    end
  end

  class RoundTerm < Term
    infix_inspect "round"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : FloorTerm)
      target = eval(term.args[0])
      Datum.new(target.number_value.floor)
    end

    def eval_term(term : CeilTerm)
      target = eval(term.args[0])
      Datum.new(target.number_value.ceil)
    end

    def eval_term(term : RoundTerm)
      target = eval(term.args[0])
      Datum.new(target.number_value.round)
    end
  end
end
