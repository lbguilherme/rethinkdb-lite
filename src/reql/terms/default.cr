module ReQL
  class DefaultTerm < Term
    register_type DEFAULT
    infix_inspect "default"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : DefaultTerm)
      begin
        eval term.args[0]
      rescue ex
        eval term.args[1]
      end
    end
  end
end
