require "../term"

module ReQL
  class SliceTerm < Term
    infix_inspect "slice"

    def check
      expect_args 2, 3
    end
  end

  class Evaluator
    def eval_term(term : SliceTerm)
      target = eval(term.args[0])

      skip = eval(term.args[1]).int64_value

      if term.args.size == 3
        limit = eval(term.args[2]).int64_value

        case
        when target.is_a? Stream
          LimitStream.new(SkipStream.new(target, skip), limit - skip)
        when array = target.array_value?
          skip = 0i64 if skip <= -array.size
          Datum.new(array[skip...limit])
        when string = target.string_value?
          skip = 0i64 if skip <= -string.size
          Datum.new(string[skip...limit])
        else
          raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
        end
      else
        case
        when target.is_a? Stream
          SkipStream.new(target, skip)
        when array = target.array_value?
          skip = 0i64 if skip <= -array.size
          Datum.new(array[skip..-1])
        when string = target.string_value?
          skip = 0i64 if skip <= -string.size
          Datum.new(string[skip..-1])
        else
          raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
        end
      end
    end
  end
end
