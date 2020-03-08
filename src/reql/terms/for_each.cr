require "../term"

module ReQL
  class ForEachTerm < Term
    infix_inspect "for_each"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : ForEachTerm)
      target = eval(term.args[0])
      func = eval(term.args[1]).as_function

      perform_writes do
        target.each do |e|
          func.eval(self, {e.as_datum})
        end
      end
    end
  end
end
