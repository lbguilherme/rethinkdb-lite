require "../term"

module ReQL
  class TableListTerm < Term
    prefix_inspect "table_list"

    def check
      expect_args 0, 1
    end
  end

  class Evaluator
    def eval_term(term : TableListTerm)
      db_name = nil

      case term.args.size
      when 0
        # TODO: Get default database name from connection / runopts
        db_name = "test"
      when 1
        db_name = eval(term.args[0]).as_database.name
      else
        raise "BUG: Wrong number of arguments"
      end

      db = @manager.databases[db_name]?
      unless db
        raise QueryLogicError.new "Database `#{db_name}` does not exist."
      end

      Datum.new(db.tables.keys)
    end
  end
end
