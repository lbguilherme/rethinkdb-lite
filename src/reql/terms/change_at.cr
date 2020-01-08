require "../term"

module ReQL
  class ChangeAtTerm < Term
    register_type CHANGE_AT
    infix_inspect "change_at"

    def compile
      expect_args 3
    end
  end

  class Evaluator
    def eval(term : ChangeAtTerm)
      arr = eval(term.args[0]).array_value

      idx_datum = eval(term.args[1])
      unless idx_datum.value.is_a? Number
        raise NonExistenceError.new("Expected type NUMBER but found #{idx_datum.reql_type}.")
      end
      idx = idx_datum.int64_value

      if idx >= arr.size
        raise NonExistenceError.new "Index `#{idx}` out of bounds for array of size: `#{arr.size}`."
      end

      if idx < 0
        old_idx = idx
        idx += arr.size

        if idx < 0 || idx >= arr.size
          raise NonExistenceError.new "Index out of bounds: #{old_idx}"
        end
      end

      val = eval(term.args[2]).as_datum

      arr = arr.dup
      arr[idx] = val
      Datum.new(arr)
    end
  end
end
