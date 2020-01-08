require "./func"

module ReQL
  struct ReqlFunc < Func
    def reql_type
      "FUNCTION"
    end

    def initialize(@vars : Array(Int64), @func : Term::Type)
    end

    def inspect(io)
      if @vars.size == 1
        io << "var_" << @vars[0] << " => "
      else
        io << "("
        io << @vars.map { |i| "var_#{i}" }.join(", ")
        io << ") => "
      end
      @func.inspect(io)
    end

    def eval(evaluator : Evaluator, args)
      if @vars.size > args.size
        raise QueryLogicError.new("Function expects #{@vars.size} arguments, but only #{args.size} available")
      end

      @vars.each.with_index do |var, i|
        if evaluator.vars.has_key? var
          raise CompileError.new("Can't shadow variable #{var}")
        end
        evaluator.vars[var] = args[i]
      end

      result = evaluator.eval(@func)

      @vars.each.with_index do |var, i|
        evaluator.vars.delete(var)
      end

      result
    end

    def encode : Bytes
      io = IO::Memory.new
      io.write_bytes(1u8)
      io.write_bytes(@vars.size.to_u32, IO::ByteFormat::LittleEndian)
      @vars.each do |var|
        io.write_bytes(var.to_u64, IO::ByteFormat::LittleEndian)
      end
      ReQL::Term.encode(@func.as(ReQL::Term::Type)).to_json(io)
      io.to_slice
    end
  end
end
