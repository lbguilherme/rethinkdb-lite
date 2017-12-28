module ReQL
  class SliceTerm < Term
    register_type SLICE
    infix_inspect "slice"

    def compile
      expect_args 2, 3
    end
  end

  class Evaluator
    def eval(term : SliceTerm)
      target = eval term.args[0]

      skip = eval term.args[1]
      expect_type skip, DatumNumber
      skip = skip.to_i64

      if term.args.size == 3
        limit = eval term.args[2]
        expect_type limit, DatumNumber
        limit = limit.to_i64

        case target
        when Stream
          LimitStream.new(SkipStream.new(target, skip), limit - skip)
        when DatumArray, DatumString
          skip = 0i64 if skip <= -target.value.size
          Datum.wrap(target.value[skip...limit])
        else
          raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
        end
      else
        case target
        when Stream
          SkipStream.new(target, skip)
        when DatumArray, DatumString
          skip = 0i64 if skip <= -target.value.size
          Datum.wrap(target.value[skip..-1])
        else
          raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
        end
      end
    end
  end
end
