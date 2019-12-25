module ReQL
  class TableTerm < Term
    register_type TABLE
    infix_inspect "table"

    def inspect(io)
      if @args.size == 2
        previous_def
        return
      end
      io << "r.table("
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
    def eval(term : TableTerm)
      db = nil
      table_name = nil

      case term.args.size
      when 1
        table_name = eval(term.args[0]).string_value
      when 2
        db = eval(term.args[0]).as_database
        table_name = eval(term.args[1]).string_value
      else
        raise "BUG: Wrong number of arguments"
      end

      unless table_name =~ /\A[A-Za-z0-9_-]+\Z/
        raise QueryLogicError.new "Table name `#{table_name}` invalid (Use A-Z, a-z, 0-9, _ and - only)."
      end

      Table.new(db, table_name, @manager)
    end
  end
end
