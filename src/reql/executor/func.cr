module ReQL
  class Func
    def self.reql_name
      "FUNCTION"
    end

    def initialize(@vars : Array(Int64), @func : Term::Type)
    end

    def eval(evaluator : Evaluator, *args)
      evaluator = evaluator.dup
      if @vars.size > args.size
        raise RuntimeError.new("Function expects #{@vars.size} arguments, but only #{args.size} available")
      end
      @vars.each.with_index do |var, i|
        evaluator.vars[var] = args[i]
      end
      evaluator.eval(@func)
    end

    def value
      raise RuntimeError.new "Query result must be of type DATUM, GROUPED_DATA, or STREAM (got FUNCTION)"
    end

    def datum
      raise RuntimeError.new "Query result must be of type DATUM, GROUPED_DATA, or STREAM (got FUNCTION)"
    end
  end
end
