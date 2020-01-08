require "../term"

module ReQL
  class FloorTerm < Term
    register_type FLOOR
    infix_inspect "floor"

    def compile
      expect_args 1
    end
  end

  class CeilTerm < Term
    register_type CEIL
    infix_inspect "ceil"

    def compile
      expect_args 1
    end
  end

  class RoundTerm < Term
    register_type ROUND
    infix_inspect "round"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : FloorTerm)
      target = eval(term.args[0])
      Datum.new(target.number_value.floor)
    end

    def eval(term : CeilTerm)
      target = eval(term.args[0])
      Datum.new(target.number_value.ceil)
    end

    def eval(term : RoundTerm)
      target = eval(term.args[0])
      Datum.new(target.number_value.round)
    end
  end
end
