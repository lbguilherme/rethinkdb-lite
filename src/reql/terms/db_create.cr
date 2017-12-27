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
      Storage::TableManager.create_db(name.value)

      Datum.new(Hash(String, Datum::Type).new)
    end
  end
end
