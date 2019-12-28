module ReQL
  struct ReqlFunc < Func
    def reql_type
      "FUNCTION"
    end

    def initialize(@vars : Array(Int64), @func : Term::Type)
    end

    def eval(evaluator : Evaluator, args)
      if @vars.size > args.size
        raise QueryLogicError.new("Function expects #{@vars.size} arguments, but only #{args.size} available")
      end

      @vars.each.with_index do |var, i|
        if evaluator.vars.has_key? var
          raise CompileError.new("Can't shadow variable #{var}")
        end
        evaluator.vars[var] = args[i]
      end

      result = evaluator.eval(@func)

      @vars.each.with_index do |var, i|
        evaluator.vars.delete(var)
      end

      result
    end
  end
end
