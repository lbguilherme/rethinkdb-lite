module ReQL
  class AppendTerm < Term
    register_type APPEND
    infix_inspect "append"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : AppendTerm)
      arr = eval term.args[0]
      expect_type arr, DatumArray
      arr = arr.value.dup

      val = eval term.args[1]
      val = val.value

      arr.push(val)

      DatumArray.new(arr)
    end
  end
end
