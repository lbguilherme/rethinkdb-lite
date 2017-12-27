module ReQL
  class LimitTerm < Term
    register_type LIMIT
    infix_inspect "limit"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : LimitTerm)
      target = eval term.args[0]
      limit = eval term.args[1]
      expect_type limit, Datum

      limit = limit.value.as(Int32 | Int64).to_i64

      case target
      when Stream
        LimitStream.new(target, limit)
      when DatumArray
        DatumArray.new(target.value[0, limit])
      else
        raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
