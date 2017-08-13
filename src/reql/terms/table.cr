module ReQL
  class TableTerm < Term
    register_type TABLE

    def inspect(io)
      io << "r.table("
      @args.each_with_index do |e, i|
        e.inspect(io)
        io << ", " unless i == @args.size - 1
      end
      io << ")"
    end

    def compile
      expect_args 1
    end
  end

  class Evalutator
    def eval(term : TableTerm)
      name = eval term.args[0]
      expect_type name, DatumString
      Table.new(Storage::TableManager.find(name.value))
    end
  end
end
