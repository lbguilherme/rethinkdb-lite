require "../term"

module ReQL
  class SpliceAtTerm < Term
    infix_inspect "splice_at"

    def check
      expect_args 3
    end
  end

  class Evaluator
    def eval_term(term : SpliceAtTerm)
      arr = eval(term.args[0]).array_value

      idx_datum = eval(term.args[1])
      unless idx_datum.value.is_a? Number
        raise NonExistenceError.new("Expected type NUMBER but found #{idx_datum.reql_type}.")
      end
      idx = idx_datum.int64_value

      if idx > arr.size
        raise NonExistenceError.new "Index `#{idx}` out of bounds for array of size: `#{arr.size}`."
      end

      if idx < 0
        old_idx = idx
        idx += arr.size + 1

        if idx < 0 || idx > arr.size
          raise NonExistenceError.new "Index out of bounds: #{old_idx}"
        end
      end

      vals = eval(term.args[2]).array_value

      arr = arr.dup
      vals.each_with_index do |val, i|
        arr.insert(idx + i, val)
      end

      Datum.new(arr)
    end
  end
end
