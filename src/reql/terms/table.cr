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
      case term.args.size
      when 1
        name = eval term.args[0]
        expect_type name, DatumString
        Table.new(nil, name.value)
      when 2
        db = eval term.args[0]
        expect_type db, Db
        name = eval term.args[1]
        expect_type name, DatumString
        Table.new(db, name.value)
      else
        raise "BUG: Wrong number of arguments"
      end
    end
  end
end
