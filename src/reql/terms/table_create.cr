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
      check_optional_args "durability", "primary_key"
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

      soft_durability = false
      if term.options.has_key? "durability"
        durability = Datum.new(term.options["durability"]).string_value
        case durability
        when "hard"
          soft_durability = false
        when "soft"
          soft_durability = true
        else
          raise QueryLogicError.new "Durability option `#{durability}` unrecognized (options are \"hard\" and \"soft\")"
        end
      end

      primary_key = "id"
      if term.options.has_key? "primary_key"
        primary_key = Datum.new(term.options["primary_key"]).string_value
      end

      @manager.create_table(db_name, table_name, primary_key, soft_durability)

      Datum.new(Hash(String, Datum::Type).new)
    end
  end
end
