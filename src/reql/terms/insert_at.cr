require "../term"

module ReQL
  class InsertAtTerm < Term
    infix_inspect "insert_at"

    def check
      expect_args 3
    end
  end

  class Evaluator
    def eval(term : InsertAtTerm)
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

      val = eval(term.args[2]).as_datum

      Datum.new(arr.dup.insert(idx, val))
    end
  end
end
