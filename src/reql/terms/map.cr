require "../term"

module ReQL
  class MapTerm < Term
    infix_inspect "map"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : MapTerm)
      target = eval(term.args[0])
      func = eval(term.args[1]).as_function

      case
      when target.is_a? Stream
        MapStream.new(target, ->(val : Datum) {
          return func.eval(self, {val}).as_datum
        })
      when array = target.array_or_set_value?
        Datum.new(array.map do |val|
          func.eval(self, {val}).value
        end)
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
