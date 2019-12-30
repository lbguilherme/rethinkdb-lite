module ReQL
  class DbCreateTerm < Term
    register_type DB_CREATE
    prefix_inspect "db_create"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : DbCreateTerm)
      name = eval(term.args[0]).string_value

      unless name =~ /\A[A-Za-z0-9_-]+\Z/
        raise QueryLogicError.new "Database name `#{name}` invalid (Use A-Z, a-z, 0-9, _ and - only)."
      end

      db_config = @manager.get_table("rethinkdb", "db_config").not_nil!

      writter = TableWriter.new
      writter.insert(db_config, {
        "name" => Datum.new(name),
      })

      Datum.new(Hash(String, Datum::Type).new)
    end
  end
end
