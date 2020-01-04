module ReQL
  class MaxTerm < Term
    register_type MAX
    infix_inspect "max"

    def compile
      expect_args 1, 2
    end
  end

  class Evaluator
    def eval(term : MaxTerm)
      target = eval(term.args[0])
      func = term.args.size == 2 ? eval(term.args[1]).as_function : nil
      best = {value: nil, computed: nil}
      target.each do |e|
        computed = func ? func.eval(self, {e.as_datum}) : e.as_datum
        best = {computed: computed, value: e} if best[:computed].nil? || computed > best[:computed]
      end
      if best[:computed] == nil
        raise QueryLogicError.new("Cannot take the max of an empty stream.")
      end
      Datum.new(best[:value])
    end
  end
end

