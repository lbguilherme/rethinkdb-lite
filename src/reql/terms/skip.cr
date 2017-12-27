module ReQL
  class SkipTerm < Term
    register_type SKIP
    infix_inspect "skip"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : SkipTerm)
      target = eval term.args[0]
      skip = eval term.args[1]
      expect_type skip, Datum

      skip = skip.value.as(Int32 | Int64).to_i64

      case target
      when Stream
        SkipStream.new(target, skip)
      when DatumArray
        array = target.value
        DatumArray.new(array.size > skip ? array[skip..-1] : [] of Datum::Type)
      else
        raise RuntimeError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
