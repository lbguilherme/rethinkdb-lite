require "../term"

module ReQL
  class SampleTerm < Term
    infix_inspect "sample"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : SampleTerm)
      target = eval(term.args[0])
      count = eval(term.args[1]).int64_value.to_i

      result = [] of Datum
      i = 0
      target.each do |val|
        if i < count
          result << val.as_datum
        else
          j = rand(i + 1)
          result[j] = val.as_datum if j < count
        end
        i += 1
      end

      Datum.new(result.shuffle)
    end
  end
end
