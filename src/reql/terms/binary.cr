require "../term"

module ReQL
  class BinaryTerm < Term
    prefix_inspect "binary"

    def check
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
