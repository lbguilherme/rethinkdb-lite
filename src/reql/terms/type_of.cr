require "../term"

module ReQL
  class TypeOfTerm < Term
    infix_inspect "type_of"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : TypeOfTerm)
      target = eval(term.args[0])
      Datum.new(target.reql_type)
    end
  end
end
