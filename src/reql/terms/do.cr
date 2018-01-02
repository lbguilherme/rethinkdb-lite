module ReQL
  class DoTerm < Term
    register_type FUNCALL
    infix_inspect "do"

    def compile
      expect_args_at_least 1
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
