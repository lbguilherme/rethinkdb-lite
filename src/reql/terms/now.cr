require "../term"

module ReQL
  class NowTerm < Term
    infix_inspect "now"

    def check
      expect_args 0
    end
  end

  class Evaluator
    def eval_term(term : NowTerm)
      p Datum.new(@now).to_json
      Datum.new(@now)
    end
  end
end
