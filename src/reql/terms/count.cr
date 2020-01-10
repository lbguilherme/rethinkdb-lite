require "../term"

module ReQL
  class CountTerm < Term
    infix_inspect "count"

    def check
      expect_args 1, 2
    end
  end

  class Evaluator
    def eval(term : CountTerm)
      target = eval(term.args[0])

      if term.args.size == 1
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
      else
        check = eval(term.args[1]).as_function
        count = 0
        target.each do |val|
          if check.eval(self, {val.as_datum}).value
            count += 1
          end
        end
        Datum.new(count)
      end
    end
  end
end
