require "../term"

module ReQL
  class GetTerm < Term
    infix_inspect "get"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : GetTerm)
      table = eval(term.args[0]).as_table
      key = eval(term.args[1]).as_datum
      table.get(key)
    end
  end
end
