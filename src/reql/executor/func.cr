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
  end
end
