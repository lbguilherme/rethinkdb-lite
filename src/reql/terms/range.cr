module ReQL
  class RangeTerm < Term
    register_type RANGE
    prefix_inspect "range"

    def compile
      expect_args(0, 2)
    end
  end

  class Evaluator
    def eval(term : RangeTerm)
      case term.args.size
      when 0
        InfiniteRange.new
      when 1
        to = eval term.args[0]
        expect_type to, DatumNumber
        Range.new(0i64, to.to_i64)
      when 2
        from = eval term.args[0]
        expect_type from, DatumNumber
        to = eval term.args[1]
        expect_type to, DatumNumber
        Range.new(from.to_i64, to.to_i64)
      else
        raise "BUG: args should be 0..2"
      end
    end
  end
end
