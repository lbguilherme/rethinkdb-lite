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

      descriptor = {
        "db"   => Datum.new(db_name),
        "name" => Datum.new(table_name),
      }

      if term.options.has_key? "durability"
        durability = Datum.new(term.options["durability"]).string_value
        case durability
        when "hard"
          descriptor["durability"] = Datum.new("hard")
        when "soft"
          descriptor["durability"] = Datum.new("soft")
        else
          raise QueryLogicError.new "Durability option `#{durability}` unrecognized (options are \"hard\" and \"soft\")"
        end
      end

      if term.options.has_key? "primary_key"
        descriptor["primary_key"] = Datum.new(Datum.new(term.options["primary_key"]).string_value)
      end

      table_config = @manager.get_table("rethinkdb", "table_config").not_nil!

      writter = TableWriter.new
      writter.insert(table_config, descriptor)

      Datum.new(Hash(String, Datum::Type).new)
    end
  end
end
