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
    return !!pattern unless pattern.is_a? Hash
    return false unless obj.is_a? Hash

    pattern.each do |(k, v)|
      return false unless obj.has_key? k
      return false unless filter_pattern_match(obj[k], v)
    end

    return true
  end

  class Evaluator
    def eval(term : FilterTerm)
      target = eval(term.args[0])
      func = eval(term.args[1])

      block = case func
              when Func
                ->(val : Datum) {
                  func.as(Func).eval(self, val).as_datum
                }
              when Datum
                ->(val : Datum) {
                  Datum.new(ReQL.filter_pattern_match(val.value, func.value))
                }
              else
                raise QueryLogicError.new("Expected type FUNCTION but found #{func.reql_type}")
              end

      case
      when target.is_a? Stream
        FilterStream.new(target, ->(val : Datum) {
          block.call(val)
        })
      when array = target.array_value
        Datum.new(array.select do |val|
          block.call(val).value
        end)
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
