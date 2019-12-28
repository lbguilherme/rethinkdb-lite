require "./func"

module ReQL
  struct FieldFunc < Func
    def reql_type
      "FUNCTION"
    end

    def initialize(@field : String)
    end

    def eval(evaluator : Evaluator, args)
      if args.size < 1
        raise QueryLogicError.new("Function expects 1 arguments, but only #{args.size} available")
      end

      obj = args[0].hash_value

      if obj.has_key? @field
        obj[@field]
      else
        raise NonExistenceError.new("No attribute `#{@field}` in object: #{JSON.build(4) { |builder| obj.to_json(builder) }}")
      end
    end
  end
end
