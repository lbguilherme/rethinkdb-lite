module ReQL
  abstract struct Func < AbstractValue
    def reql_type
      "FUNCTION"
    end

    abstract def eval(evaluator : Evaluator, args)

    def value : Type
      raise QueryLogicError.new "Query result must be of type DATUM, GROUPED_DATA, or STREAM (got FUNCTION)."
    end

    def as_function
      self
    end

    abstract def encode : Bytes

    def self.decode(bytes : Bytes)
      io = IO::Memory.new(bytes, false)
      case io.read_bytes(UInt8)
      when 1
        vars = [] of Int64
        io.read_bytes(UInt32, IO::ByteFormat::LittleEndian).times do
          vars << io.read_bytes(UInt64, IO::ByteFormat::LittleEndian).to_i64
        end
        func = ReQL::Term.parse(JSON.parse(io))
        ReqlFunc.new(vars, func)
      when 2
        field = io.read_string(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
        FieldFunc.new(field)
      when 3
        bytecode = Bytes.new(io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
        io.read_fully(bytecode)
        JsFunc.new(bytecode)
      else
        raise "BUG: Unknown function encoding"
      end
    end
  end
end
