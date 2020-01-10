require "../term"

module ReQL
  class LimitTerm < Term
    infix_inspect "limit"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : LimitTerm)
      target = eval(term.args[0])
      limit = eval(term.args[1]).int64_value

      case
      when target.is_a? Stream
        LimitStream.new(target, limit)
      when array = target.array_value?
        Datum.new(array[0, limit])
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
