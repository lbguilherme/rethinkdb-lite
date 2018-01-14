module ReQL
  class ErrorTerm < Term
    register_type ERROR
    infix_inspect "error"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : ErrorTerm)
      message = eval term.args[0]
      expect_type message, DatumString

      raise UserError.new message.value
    end
  end
end
