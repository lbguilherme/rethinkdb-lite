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
      base = begin
        eval term.args[0]
      rescue ex
        Datum.wrap(nil)
      end

      if base.is_a? Datum && !base.value
        eval term.args[1]
      else
        base
      end
    end
  end
end
