require "../term"

module ReQL
  class DbListTerm < Term
    prefix_inspect "db_list"

    def check
      expect_args 0
    end
  end

  class Evaluator
    def eval_term(term : DbListTerm)
      Datum.new(@manager.databases.keys)
    end
  end
end
