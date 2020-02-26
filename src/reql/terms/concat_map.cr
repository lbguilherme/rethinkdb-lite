require "../term"

module ReQL
  class ConcatMapTerm < Term
    infix_inspect "concat_map"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : ConcatMapTerm)
      target = eval(term.args[0])
      func = eval(term.args[1]).as_function

      case
      when target.is_a? Stream
        ConcatMapStream.new(target, ->(val : Datum) {
          return func.eval(self, {val}).as_datum
        })
      when array = target.array_or_set_value?
        Datum.new(array.flat_map do |val|
          func.eval(self, {val}).array_value
        end)
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
