module ReQL
  class TypeOfTerm < Term
    register_type TYPE_OF
    infix_inspect "type_of"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : TypeOfTerm)
      target = eval term.args[0]
      Datum.wrap(target.class.reql_name)
    end
  end
end
