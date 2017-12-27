module ReQL
  class DbTerm < Term
    register_type DB

    def inspect(io)
      io << "r.db("
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

  class Evaluator
    def eval(term : DbTerm)
      name = eval term.args[0]
      expect_type name, DatumString
      Db.new(name.value)
    end
  end
end
