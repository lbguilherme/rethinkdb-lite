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
      func = eval(term.args[-1])
      args = eval(term.args[0..-2]).array_value
      if func.is_a? Func
        case args.size
        when 0
          func.eval(self).as_datum
        when 1
          func.eval(self, args[0]).as_datum
        when 2
          func.eval(self, args[0], args[1]).as_datum
        when 3
          func.eval(self, args[0], args[1], args[2]).as_datum
        else
          raise QueryLogicError.new("Too many arguments for r.do term")
        end
      else
        return func
      end
    end
  end
end
