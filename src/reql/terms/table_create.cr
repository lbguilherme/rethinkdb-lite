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
        db_name = "test"
        table_name = eval(term.args[0]).string_value
      when 2
        db_name = eval(term.args[0]).as_database.name
        table_name = eval(term.args[1]).string_value
      end

      unless table_name =~ /\A[A-Za-z0-9_-]+\Z/
        raise QueryLogicError.new "Table name `#{table_name}` invalid (Use A-Z, a-z, 0-9, _ and - only)."
      end

      if @manager.get_table(db_name, table_name)
        raise OpFailedError.new("Table `#{db_name}.#{table_name}` already exists")
      end

      @manager.create_table(db_name, table_name)

      Datum.new(Hash(String, Datum::Type).new)
    end
  end
end
