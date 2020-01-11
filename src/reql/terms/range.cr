require "../term"

module ReQL
  class RangeTerm < Term
    prefix_inspect "range"

    def check
      expect_args 0, 2
    end
  end

  class Evaluator
    def eval_term(term : RangeTerm)
      case term.args.size
      when 0
        InfiniteRange.new
      when 1
        to = eval(term.args[0]).int64_value
        Range.new(0i64, to)
      when 2
        from = eval(term.args[0]).int64_value
        to = eval(term.args[1]).int64_value
        Range.new(from, to)
      else
        raise "BUG: args should be 0..2"
      end
    end
  end
end
