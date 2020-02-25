require "../term"

module ReQL
  class SumTerm < Term
    infix_inspect "sum"

    def check
      expect_args 1, 2
    end
  end

  class Evaluator
    def eval_term(term : SumTerm)
      target = eval(term.args[0])

      sum = 0i64
      if term.args.size == 1
        target.each do |e|
          sum += e.number_value
        end
      elsif term.args.size == 2
        func = eval(term.args[1]).as_function
        target.each do |e|
          sum += func.eval(self, {e.as_datum}).number_value
        end
      end

      Datum.new(sum)
    end
  end
end
