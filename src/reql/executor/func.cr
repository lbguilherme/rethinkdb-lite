module ReQL
  abstract class Func
    def self.reql_name
      "FUNCTION"
    end

    abstract def eval(evaluator : Evaluator, *args)

    def value
      raise QueryLogicError.new "Query result must be of type DATUM, GROUPED_DATA, or STREAM (got FUNCTION)."
    end

    def datum
      raise QueryLogicError.new "Query result must be of type DATUM, GROUPED_DATA, or STREAM (got FUNCTION)."
    end
  end
end
