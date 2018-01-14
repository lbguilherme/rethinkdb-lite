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
      first = eval term.args[0]

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          val = eval arg
          expect_type val, DatumNumber
          result += val.value
        when String
          val = eval arg
          expect_type val, DatumString
          result += val.value
        when Array
          val = eval arg
          expect_type val, DatumArray
          result += val.value
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.class.reql_name}.")
        end
      end

      return Datum.wrap(result)
    end

    def eval(term : SubTerm)
      first = eval term.args[0]

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          val = eval arg
          expect_type val, DatumNumber
          result -= val.value
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.class.reql_name}.")
        end
      end

      return Datum.wrap(result)
    end

    def eval(term : MulTerm)
      first = eval term.args[0]

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          val = eval arg
          case val
          when DatumNumber
            result *= val.value
          when DatumArray
            result = val.value * DatumNumber.new(result).to_i64
          else
            raise QueryLogicError.new("Expected type NUMBER but found #{val.class.reql_name}.")
          end
        when Array
          val = eval arg
          expect_type val, DatumNumber
          result *= val.to_i64
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.class.reql_name}.")
        end
      end

      return Datum.wrap(result)
    end

    def eval(term : DivTerm)
      first = eval term.args[0]

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          val = eval arg
          expect_type val, DatumNumber
          if val.value == 0
            raise QueryLogicError.new("Cannot divide by zero.")
          end
          result /= val.to_f64
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.class.reql_name}.")
        end
      end

      return Datum.wrap(result)
    end

    def eval(term : ModTerm)
      first = eval term.args[0]

      result = first.value
      term.args[1..-1].each do |arg|
        case result
        when Number
          val = eval arg
          expect_type val, DatumNumber
          if val.value == 0
            raise QueryLogicError.new("Cannot divide by zero.")
          end
          result = result.to_f64 % val.to_f64
        else
          raise QueryLogicError.new("Expected type NUMBER but found #{first.class.reql_name}.")
        end
      end

      return Datum.wrap(result)
    end
  end
end
