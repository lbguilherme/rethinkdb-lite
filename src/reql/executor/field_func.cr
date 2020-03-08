require "./func"

module ReQL
  struct FieldFunc < Func
    def reql_type
      "FUNCTION"
    end

    def initialize(@field : String)
    end

    def inspect(io)
      io << "row => row("
      @field.inspect(io)
      io << ")"
    end

    def eval(evaluator : Evaluator, args)
      if args.size < 1
        raise QueryLogicError.new("Function expects 1 arguments, but only #{args.size} available")
      end

      obj = args[0].as_datum.hash_value

      if obj.has_key? @field
        obj[@field]
      else
        raise NonExistenceError.new("No attribute `#{@field}` in object: #{JSON.build(4) { |builder| obj.to_json(builder) }}")
      end
    end

    def encode : Bytes
      io = IO::Memory.new
      io.write_bytes(2u8)
      io.write_bytes(@field.bytesize.to_u32, IO::ByteFormat::LittleEndian)
      io.write(@field.to_slice)
      io.to_slice
    end
  end
end
