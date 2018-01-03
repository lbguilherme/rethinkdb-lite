module ReQL
  class MinvalTerm < Term
    register_type MINVAL
    prefix_inspect "minval"

    def compile
      expect_args 0
    end
  end

  class MaxvalTerm < Term
    register_type MAXVAL
    prefix_inspect "maxval"

    def compile
      expect_args 0
    end
  end

  class Evaluator
    def eval(term : MinvalTerm)
      DatumMinval.new
    end

    def eval(term : MaxvalTerm)
      DatumMaxval.new
    end
  end
end
