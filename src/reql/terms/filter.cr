module ReQL
  class FilterTerm < Term
    register_type FILTER
    infix_inspect "filter"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : FilterTerm)
      target = eval term.args[0]
      func = eval term.args[1]
      expect_type func, Func

      case target
      when Stream
        FilterStream.new(target, ->(val : Datum) {
          return func.as(Func).eval(self, val).datum
        })
      when DatumArray
        DatumArray.new(target.value.select do |val|
          func.as(Func).eval(self, Datum.wrap(val)).value.as(Datum::Type)
        end)
      else
        raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
