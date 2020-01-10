require "../helpers/object_selection"
require "../term"

module ReQL
  class WithoutTerm < Term
    infix_inspect "without"

    def check
      expect_args_at_least 2
    end
  end

  class Evaluator
    def eval(term : WithoutTerm)
      target = eval(term.args[0])
      selection = ObjectSelection.new

      term.args[1..-1].each do |arg|
        selection.add(eval(arg).as_datum)
      end

      case target
      when Stream
        MapStream.new(target.as(Stream), ->(val : Datum) {
          case val
          when .is_array?
            raise QueryLogicError.new("Cannot perform without on a sequence of sequences")
          when .is_hash?
            selection.reject_on_object(val)
          else
            raise QueryLogicError.new("Cannot perform without on a non-object non-sequence `#{target.value.inspect}`")
          end
        })
      when .is_array?
        Datum.new(target.array_value.map do |val|
          case val
          when .is_array?
            raise QueryLogicError.new("Cannot perform without on a sequence of sequences")
          when .is_hash?
            selection.reject_on_object(val)
          else
            raise QueryLogicError.new("Cannot perform without on a non-object non-sequence `#{target.value.inspect}`")
          end
        end)
      when .is_hash?
        selection.reject_on_object(target.as_datum)
      else
        raise QueryLogicError.new("Cannot perform without on a non-object non-sequence `#{target.value.inspect}`")
      end
    end
  end
end
