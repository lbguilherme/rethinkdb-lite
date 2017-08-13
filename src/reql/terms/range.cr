module ReQL
  class RangeTerm < Term
    register_type RANGE
    prefix_inspect "range"

    def compile
      expect_args(0, 2)
    end
  end

  class Term
    def self.eval(term : RangeTerm)
      case term.args.size
      when 0
        Range.new(0i64, nil)
      when 1
        from = eval term.args[0]
        expect_type from, Datum
        Range.new(from.value.as(Int64), nil)
      when 2
        from = eval term.args[0]
        expect_type from, Datum
        to = eval term.args[1]
        expect_type to, Datum
        Range.new(from.value.as(Int64), to.value.as(Int64))
      else
        raise "BUG: args should be 0..2"
      end
    end
  end
end
