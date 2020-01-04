module ReQL
  class RandomTerm < Term
    register_type RANDOM
    prefix_inspect "random"

    def compile
      expect_args 0,2
      check_optional_args "float"
    end
  end

  class Evaluator
    def eval(term : RandomTerm)
      is_float = (term.options.has_key? "float") && term.options["float"]
      case term.args.size
      when 0
        Datum.new(Random.rand)
      when 1
        if is_float
          max = eval(term.args[0]).float64_value
          Datum.new(Random.rand(max))
        else
          max = eval(term.args[0]).int64_value
          Datum.new(Random.rand(max))
        end
      when 2
        if is_float
          min = eval(term.args[0]).float64_value
          max = eval(term.args[1]).float64_value
          Datum.new(Random.rand(min...max))
        else
          min = eval(term.args[0]).int64_value
          max = eval(term.args[1]).int64_value
          Datum.new(Random.rand(min...max))
        end
      else
        raise "Expected between 0 and 2 arguments but found" + term.args.size.to_s
      end
    end
  end
end


