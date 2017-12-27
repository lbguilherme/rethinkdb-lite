module ReQL
  class TableCreateTerm < Term
    register_type TABLE_CREATE
    infix_inspect "table_create"

    def inspect(io)
      if @args.size == 2
        previous_def
        return
      end
      io << "r.table_create("
      @args.each_with_index do |e, i|
        e.inspect(io)
        io << ", " unless i == @args.size - 1
      end
      io << ")"
    end

    def compile
      expect_args 1, 2
    end
  end

  class Evaluator
    def eval(term : TableCreateTerm)
      db_name = ""
      table_name = ""
      case term.args.size
      when 1
        name = eval term.args[0]
        expect_type name, DatumString
        db_name = "test"
        table_name = name.value
      when 2
        db = eval term.args[0]
        expect_type db, Db
        name = eval term.args[1]
        expect_type name, DatumString
        db_name = db.name
        table_name = name.value
      end

      if Storage::TableManager.find_table(db_name, table_name)
        raise RuntimeError.new("Table `#{db_name}.#{table_name}` already exists")
      end

      Storage::TableManager.create_table(db_name, table_name)

      Datum.new(Hash(String, Datum::Type).new)
    end
  end
end
