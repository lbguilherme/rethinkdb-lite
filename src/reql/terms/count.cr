module ReQL
  class CountTerm < Term
    register_type COUNT
    infix_inspect "count"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : CountTerm)
      target = eval(term.args[0])

      case
      when target.is_a? Stream
        Datum.new(target.count(Int32::MAX.to_i64))
      when array = target.array_value?
        Datum.new(array.size.to_i64)
      when string = target.string_value?
        Datum.new(string.size.to_i64)
      when bytes = target.bytes_value?
        Datum.new(bytes.size.to_i64)
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
