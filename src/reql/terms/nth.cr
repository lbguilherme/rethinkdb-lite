require "../term"

module ReQL
  class NthTerm < Term
    infix_inspect "nth"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : NthTerm)
      target = eval(term.args[0])
      index = eval(term.args[1]).int64_value.to_i

      case
      when target.is_a? Stream
        target.start_reading
        begin
          if index >= 0
            target.skip(index)
            val = target.next_val
            if val
              return val
            else
              raise NonExistenceError.new "Index out of bounds: #{index}"
            end
          else
            deque = Deque(AbstractValue).new
            while val = target.next_val
              deque << val
              if deque.size > -index
                deque.shift
              end
            end
            if deque.size == -index
              return deque[0]
            else
              raise NonExistenceError.new "Index out of bounds: #{index}"
            end
          end
        ensure
          target.finish_reading
        end
      when array = target.array_value?
        if index >= array.size
          raise NonExistenceError.new "Index out of bounds: #{index}"
        end

        if index < 0
          old_index = index
          index += array.size

          if index < 0 || index >= array.size
            raise NonExistenceError.new "Index out of bounds: #{old_index}"
          end
        end

        return Datum.new(array[index])
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
