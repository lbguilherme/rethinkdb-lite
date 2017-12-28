module ReQL
  class FilterTerm < Term
    register_type FILTER
    infix_inspect "filter"

    def compile
      expect_args 2
    end
  end

  def self.filter_pattern_match(obj, pattern)
    return true if obj == pattern
    return false unless obj.is_a? Hash
    return false unless pattern.is_a? Hash

    pattern.each do |(k, v)|
      return false unless obj.has_key? k
      return false unless filter_pattern_match(obj[k], v)
    end

    return true
  end

  class Evaluator
    def eval(term : FilterTerm)
      target = eval term.args[0]
      func = eval term.args[1]

      block = case func
      when Func
        ->(val : Datum) {
          func.as(Func).eval(self, val).datum
        }
      when Datum
        ->(val : Datum) {
          Datum.wrap(ReQL.filter_pattern_match(val.value, func.value))
        }
      else
        raise QueryLogicError.new("Expected type FUNCTION but found #{func.class.reql_name}")
      end

      case target
      when Stream
        FilterStream.new(target, ->(val : Datum) {
          block.call(val)
        })
      when DatumArray
        DatumArray.new(target.value.select do |val|
          block.call(Datum.wrap(val)).value.as(Datum::Type)
        end)
      else
        raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
