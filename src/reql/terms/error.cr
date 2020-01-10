require "../term"

module ReQL
  class ErrorTerm < Term
    infix_inspect "error"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : ErrorTerm)
      message = eval(term.args[0])
      raise UserError.new message.string_value
    end
  end
end
