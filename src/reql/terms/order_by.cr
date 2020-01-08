require "../term"

module ReQL
  class OrderByTerm < Term
    register_type ORDER_BY
    infix_inspect "order_by"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : OrderByTerm)
      target = eval(term.args[0])
      func = eval(term.args[1])

      array = if target.is_a? Stream || target.reql_type == "ARRAY"
                target.array_value
              else
                raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
              end

      Datum.new(array.sort_by do |val|
        case
        when key = func.string_value?
          case val
          when Array
            raise QueryLogicError.new("Cannot perform bracket on a sequence of sequences")
          when Hash
            val[key]
          else
            raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence `#{val.inspect}`.")
          end
        when func.is_a? Func
          func.eval(self, {val})
        else
          raise QueryLogicError.new("Expected type STRING but found #{func.reql_type}")
        end
      end)
    end
  end
end
