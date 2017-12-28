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
      name = eval term.args[0]
      expect_type name, DatumString
      name = name.value

      unless name =~ /\A[A-Za-z0-9_-]+\Z/
        raise QueryLogicError.new "Database name `#{name}` invalid (Use A-Z, a-z, 0-9, _ and - only)."
      end

      Storage::TableManager.create_db(name)

      Datum.wrap(Hash(String, Datum::Type).new)
    end
  end
end
