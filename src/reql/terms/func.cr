module ReQL
  class FuncTerm < Term
    register_type FUNC

    def inspect(io)
      vars = @args[0].as(Array)
      body = @args[1]
      if vars.size == 1
        io << "var" << vars[0] << " => "
      else
        io << "("
        vars.map { |i| "var#{i}" }.join(", ")
        io << ") => "
      end
      body.inspect(io)
    end

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : FuncTerm)
      Func.new(term.args[0].as(Array).map { |x| x.as(Int64) }, term.args[1])
    end
  end
end
