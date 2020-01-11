require "../term"

module ReQL
  class AddTerm < Term
    infix_inspect "add"

    def check
      expect_args_at_least 1
    end
  end

  class SubTerm < Term
    infix_inspect "sub"

    def check
      expect_args_at_least 1
    end
  end

  class MulTerm < Term
    infix_inspect "mul"

    def check
      expect_args_at_least 1
    end
  end

  class DivTerm < Term
    infix_inspect "div"

    def check
      expect_args_at_least 1
    end
  end

  class ModTerm < Term
    infix_inspect "mod"

    def check
      expect_args_at_least 1
    end
  end

  class Evaluator
    def eval_term(term : AddTerm)
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

    def eval_term(term : SubTerm)
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

    def eval_term(term : MulTerm)
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

    def eval_term(term : DivTerm)
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

    def eval_term(term : ModTerm)
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
