module ReQL
  class BinaryTerm < Term
    register_type BINARY
    prefix_inspect "binary"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : BinaryTerm)
      data = eval(term.args[0])

      if data.is_bytes?
        return data
      end

      Datum.new(data.string_value.to_slice)
    end
  end
end
