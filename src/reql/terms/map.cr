module ReQL
  class MapTerm < Term
    register_type MAP
    infix_inspect "map"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : MapTerm)
      target = eval term.args[0]
      func = eval term.args[1]
      expect_type func, Func

      case target
      # when Stream
      #   Datum.new(target.count)
      when DatumArray
        DatumArray.new(target.value.map do |val|
          func.eval(self, Datum.wrap(val)).value.as(Datum::Type)
        end)
      else
        raise RuntimeError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
