module ReQL
  class InsertAtTerm < Term
    register_type INSERT_AT
    infix_inspect "insert_at"

    def compile
      expect_args 3
    end
  end

  class Evaluator
    def eval(term : InsertAtTerm)
      arr = eval term.args[0]
      expect_type arr, DatumArray
      arr = arr.value

      idx = eval term.args[1]
      unless idx.is_a? DatumNumber
        raise NonExistenceError.new("Expected type #{DatumNumber.reql_name} but found #{idx.class.reql_name}.")
      end
      idx = idx.to_i64

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

      val = eval term.args[2]
      val = val.value

      DatumArray.new(arr.dup.insert(idx, val))
    end
  end
end
