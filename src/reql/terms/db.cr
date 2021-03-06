require "../term"

module ReQL
  class DbTerm < Term
    def inspect(io)
      io << "r.db("
      @args.each_with_index do |e, i|
        e.inspect(io)
        io << ", " unless i == @args.size - 1
      end
      io << ")"
    end

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : DbTerm)
      name = eval(term.args[0]).string_value

      unless name =~ /\A[A-Za-z0-9_-]+\Z/
        raise QueryLogicError.new "Database name `#{name}` invalid (Use A-Z, a-z, 0-9, _ and - only)."
      end

      Db.new(name)
    end
  end
end
