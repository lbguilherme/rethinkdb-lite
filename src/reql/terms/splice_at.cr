module ReQL
  class SpliceAtTerm < Term
    register_type SPLICE_AT
    infix_inspect "splice_at"

    def compile
      expect_args 3
    end
  end

  class Evaluator
    def eval(term : SpliceAtTerm)
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

      vals = eval term.args[2]
      expect_type vals, DatumArray
      vals = vals.value

      arr = arr.dup
      vals.each_with_index do |val, i|
        arr.insert(idx + i, val)
      end

      DatumArray.new(arr)
    end
  end
end
