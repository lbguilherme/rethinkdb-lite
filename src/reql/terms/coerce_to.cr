module ReQL
  class CoerceToTerm < Term
    register_type COERCE_TO
    infix_inspect "coerce_to"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : CoerceToTerm)
      source = eval term.args[0]
      target_type = eval term.args[1]
      expect_type target_type, DatumString
      target_type = target_type.value.upcase

      if source.class.reql_name == target_type
        return source
      end

      case target_type
      when "NUMBER"
        case source
        when DatumString
          return Datum.wrap(source.value.to_f64)
        end
      when "STRING"
        case source
        when DatumNumber
          return Datum.wrap(source.value.to_s)
        when DatumBool
          return Datum.wrap(source.value.to_s)
        when DatumNull
          return Datum.wrap("null")
        end
      when "BOOL"
        case source
        when DatumNull
          return Datum.wrap(false)
        when Datum
          return Datum.wrap(true)
        end
      when "NULL"
      else
        raise QueryLogicError.new "Unknown Type: #{target_type}"
      end

      raise QueryLogicError.new "Cannot coerce #{source.class.reql_name} to #{target_type}"
    end
  end
end
