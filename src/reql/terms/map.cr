require "../term"

module ReQL
  class MapTerm < Term
    infix_inspect "map"

    def check
      expect_args_at_least 2
    end
  end

  class Evaluator
    def eval_term(term : MapTerm)
      targets = term.args[0..-2].map { |arg| eval(arg) }
      func = eval(term.args[-1]).as_function

      if targets.any? &.is_a? Stream
        streams = targets.map { |target| target.is_a?(Stream) ? target : ArrayStream.new(target.array_value) }
        MapStream.new(streams, ->(vals : Array(Datum)) {
          return func.eval(self, vals).as_datum
        })
      else
        arrays = targets.map &.array_value
        result = [] of Datum
        i = 0
        while arrays.all? { |array| i < array.size }
          result << func.eval(self, arrays.map(&.[i])).as_datum
          i += 1
        end
        Datum.new(result)
      end
    end
  end
end
