module ReQL
  class AddTerm < Term
    register_type ADD
    infix_inspect "add"

    def compile
      expect_args_at_least 1
    end
  end

  class SubTerm < Term
    register_type SUB
    infix_inspect "sub"

    def compile
      expect_args_at_least 1
    end
  end

  class MulTerm < Term
    register_type MUL
    infix_inspect "mul"

    def compile
      expect_args_at_least 1
    end
  end

  class DivTerm < Term
    register_type DIV
    infix_inspect "div"

    def compile
      expect_args_at_least 1
    end
  end

  class ModTerm < Term
    register_type MOD
    infix_inspect "mod"

    def compile
      expect_args_at_least 1
    end
  end

  class Evaluator
    def eval(term : AddTerm)
      first = eval(term.args[0])

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          result += eval(arg).number_value
        when String
          result += eval(arg).string_value
        when Array
          result += eval(arg).array_value
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.reql_type}.")
        end
      end

      return Datum.new(result)
    end

    def eval(term : SubTerm)
      first = eval(term.args[0])

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          result -= eval(arg).number_value
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.reql_type}.")
        end
      end

      return Datum.new(result)
    end

    def eval(term : MulTerm)
      first = eval(term.args[0])

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          val = eval(arg)
          case
          when number = val.number_value?
            result *= number
          when array = val.array_value?
            result = array * Datum.new(result).int64_value
          else
            raise QueryLogicError.new("Expected type NUMBER but found #{val.reql_type}.")
          end
        when Array
          result *= eval(arg).int64_value
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.reql_type}.")
        end
      end

      return Datum.new(result)
    end

    def eval(term : DivTerm)
      first = eval(term.args[0])

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          val = eval(arg).number_value
          if val == 0
            raise QueryLogicError.new("Cannot divide by zero.")
          end
          result /= val.to_f64
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.reql_type}.")
        end
      end

      return Datum.new(result)
    end

    def eval(term : ModTerm)
      first = eval(term.args[0])

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          val = eval(arg).number_value
          if val == 0
            raise QueryLogicError.new("Cannot divide by zero.")
          end
          result = result.to_f64 % val.to_f64
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.reql_type}.")
        end
      end

      return Datum.new(result)
    end
  end
end
