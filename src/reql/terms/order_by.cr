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
      target = eval term.args[0]
      func = eval term.args[1]

      case target
      when Stream, DatumArray
        a = target.value.map &.as(Array(Datum::Type) | Bool | Float64 | Hash(String, Datum::Type) | Int64 | Int32 | String | Nil)
        DatumArray.new(a.sort_by { |val|
          case func
          when DatumString
            unless val.is_a? Array
              raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence")
            end
            val.map { |val|
              case val
              when Array
                raise QueryLogicError.new("Cannot perform bracket on a sequence of sequences")
              when Hash
                val[func.value]
              else
                raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence")
              end
            }
          when Func
            func.eval(self, Datum.wrap(val)).value
          else
            raise QueryLogicError.new("Expected type STRING but found #{func.class.reql_name}")
          end.as(String)
        }.map &.as(Datum::Type))
      else
        raise QueryLogicError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end

