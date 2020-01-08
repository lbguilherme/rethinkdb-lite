require "../term"

module ReQL
  class RangeTerm < Term
    register_type RANGE
    prefix_inspect "range"

    def compile
      expect_args 0, 2
    end
  end

  class Evaluator
    def eval(term : RangeTerm)
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
