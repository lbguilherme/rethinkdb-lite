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
      target = eval term.args[0]
      expect_type target, DatumNumber

      Datum.wrap(target.value.floor)
    end

    def eval(term : CeilTerm)
      target = eval term.args[0]
      expect_type target, DatumNumber

      Datum.wrap(target.value.ceil)
    end

    def eval(term : RoundTerm)
      target = eval term.args[0]
      expect_type target, DatumNumber

      Datum.wrap(target.value.round)
    end
  end
end
