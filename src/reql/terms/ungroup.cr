require "../term"

module ReQL
  class UngroupTerm < Term
    infix_inspect "ungroup"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : UngroupTerm)
      if term.args[0].is_a? GroupTerm
        eval(term.args[0])
      else
        raise QueryLogicError.new("Cannot ungroup() something that is not a group()")
      end
    end
  end
end
