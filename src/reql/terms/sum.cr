require "../term"

module ReQL
  class SumTerm < Term
    infix_inspect "sum"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : SumTerm)
      target = eval(term.args[0])

      sum = 0i64
      target.each do |e|
        sum += e.number_value
      end

      Datum.new(sum)
    end
  end
end
