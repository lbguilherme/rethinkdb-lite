require "../term"

module ReQL
  class OrderByTerm < Term
    infix_inspect "order_by"

    def check
      expect_args_at_least 2
    end
  end

  class Evaluator
    def eval_term(term : OrderByTerm)
      target = eval(term.args[0])
      asc = [] of Bool
      funcs = term.args[1..-1].map_with_index do |arg, i|
        if arg.is_a? AscTerm
          arg.expect_args(1)
          arg = arg.args[0]
          asc << true
        elsif arg.is_a? DescTerm
          arg.expect_args(1)
          arg = arg.args[0]
          asc << false
        else
          asc << true
        end

        eval(arg)
      end

      array = if target.is_a? Stream || target.reql_type == "ARRAY"
                target.array_value
              else
                raise QueryLogicError.new("Cannot convert #{target.reql_type} to SEQUENCE")
              end

      Datum.new(array.sort do |a, b|
        cmp = 0
        funcs.each_with_index do |func, i|
          cmp = apply_func(self, func, a) <=> apply_func(self, func, b)
          cmp = -cmp if asc[i] == false
          break if cmp != 0
        end
        cmp
      end)
    end
  end
end

private def apply_func(evaluator, func, val) : ReQL::Datum
  case
  when key = func.string_value?
    case val
    when Array
      raise ReQL::QueryLogicError.new("Cannot perform bracket on a sequence of sequences")
    when Hash
      val[key]
    else
      raise ReQL::QueryLogicError.new("Cannot perform bracket on a non-object non-sequence `#{val.inspect}`.")
    end
  when func.is_a? ReQL::Func
    func.eval(evaluator, {val}).as_datum
  else
    raise ReQL::QueryLogicError.new("Expected type STRING but found #{func.reql_type}")
  end
end
