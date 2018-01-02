module ReQL
  class DoTerm < Term
    register_type FUNCALL
    infix_inspect "do"

    def compile
      if @args.size == 0
        raise CompileError.new "Expected 1 or more arguments but found 0."
      end
    end
  end

  class Evaluator
    def eval(term : DoTerm)
      func = eval term.args[-1]
      expect_type func, Func

      args = eval term.args[0..-2]
      args = args.value.map { |val| Datum.wrap(val) }

      case args.size
      when 0
        func.eval(self).datum
      when 1
        func.eval(self, args[0]).datum
      when 2
        func.eval(self, args[0], args[1]).datum
      else
        raise QueryLogicError.new("Too many arguments for r.do term")
      end
    end
  end
end
