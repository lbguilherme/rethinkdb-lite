module ReQL
  class AddTerm < Term
    register_type ADD
    infix_inspect "add"

    def compile
      expect_args_at_least 1
    end
  end

  class Evaluator
    def eval(term : AddTerm)
      first = eval term.args[0]
      list = eval term.args[1..-1]

      return Datum.wrap(first.value) if term.args == 1

      case first
      when DatumNumber
        result = first.value
        term.args[1..-1].each do |arg|
          val = eval arg
          expect_type val, DatumNumber
          result += val.value
        end
        return DatumNumber.new(result)
      when DatumString
        result = first.value
        term.args[1..-1].each do |arg|
          val = eval arg
          expect_type val, DatumString
          result += val.value
        end
        return DatumString.new(result)
      when DatumArray
        result = first.value
        term.args[1..-1].each do |arg|
          val = eval arg
          expect_type val, DatumArray
          result += val.value
        end
        return DatumArray.new(result)
      else
        raise QueryLogicError.new("Expected type NUMBER but found #{first.class.reql_name}.")
      end
    end
  end

  class SubTerm < Term
    register_type SUB
    infix_inspect "sub"

    def compile
      expect_args_at_least 1
    end
  end

  class Evaluator
    def eval(term : SubTerm)
      first = eval term.args[0]
      list = eval term.args[1..-1]

      return Datum.wrap(first.value) if term.args == 1

      case first
      when DatumNumber
        result = first.value
        term.args[1..-1].each do |arg|
          val = eval arg
          expect_type val, DatumNumber
          result -= val.value
        end
        return DatumNumber.new(result)
      else
        raise QueryLogicError.new("Expected type NUMBER but found #{first.class.reql_name}.")
      end
    end
  end
end
