module ReQL
  class CountTerm < Term
    register_type COUNT
    infix_inspect "count"

    def compile
      expect_args 1
    end
  end

  class Evalutator
    def eval(term : CountTerm)
      target = eval term.args[0]

      case target
      when Stream
        Datum.new(target.count)
      when DatumArray, DatumString
        Datum.new(target.value.size.to_i64)
      else
        raise RuntimeError.new("Cannot convert #{target.class.reql_name} to SEQUENCE")
      end
    end
  end
end
