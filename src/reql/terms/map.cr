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
      target = eval(term.args[0])
      func = eval(term.args[1]).as_function

      case
      when target.is_a? Stream
        MapStream.new(target, ->(val : Datum) {
          return func.eval(self, {val}).as_datum
        })
      when array = target.array_value?
        Datum.new(array.map do |val|
          func.eval(self, {val}).value
        end)
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
