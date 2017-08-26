module ReQL
  class SliceTerm < Term
    register_type SLICE
    infix_inspect "slice"

    def compile
      expect_args 3
    end
  end

  class Evaluator
    def eval(term : SliceTerm)
      target = eval term.args[0]
      skip = eval term.args[1]
      expect_type skip, Datum
      limit = eval term.args[2]
      expect_type limit, Datum

      skip = skip.value.as(Int64)
      limit = limit.value.as(Int64)

      case target
      when Stream
        LimitStream.new(SkipStream.new(target, skip), limit)
      when DatumArray
        DatumArray.new(target.value[skip, limit])
      else
        raise RuntimeError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
