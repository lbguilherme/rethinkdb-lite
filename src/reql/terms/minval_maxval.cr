require "../term"

module ReQL
  class MinvalTerm < Term
    prefix_inspect "minval"

    def check
      expect_args 0
    end
  end

  class MaxvalTerm < Term
    prefix_inspect "maxval"

    def check
      expect_args 0
    end
  end

  class Evaluator
    def eval_term(term : MinvalTerm)
      Datum.new(Minval.new)
    end

    def eval_term(term : MaxvalTerm)
      Datum.new(Maxval.new)
    end
  end
end
