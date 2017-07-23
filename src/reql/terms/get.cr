module ReQL
  class GetTerm < Term
    register_type GET
    infix_inspect "get"

    def compile
      expect_args 2
    end
  end

  class Term
    def self.eval(term : GetTerm)
      table = eval term.args[0]
      expect_type table, Table
      key = eval term.args[1]
      expect_type key, Datum
      table.get(key.value)
    end
  end
end
