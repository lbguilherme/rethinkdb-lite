require "../term"

module ReQL
  class SkipTerm < Term
    infix_inspect "skip"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : SkipTerm)
      target = eval(term.args[0])
      skip = eval(term.args[1]).int64_value

      case
      when target.is_a? Stream
        SkipStream.new(target, skip)
      when array = target.array_value?
        Datum.new(array.size > skip ? array[skip..-1] : [] of Datum)
      else
        raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
      end
    end
  end
end
