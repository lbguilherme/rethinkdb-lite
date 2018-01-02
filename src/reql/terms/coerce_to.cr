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

      unless source.is_a? Datum
        source = source.datum
      end

      case target_type
      when "NUMBER"
        case source
        when DatumString
          begin
            return DatumNumber.new(source.value.to_f64)
          rescue ex : ArgumentError
            raise QueryLogicError.new "Could not coerce `#{source.value}` to NUMBER."
          end
        end
      when "STRING"
        case source
        when DatumObject
          return DatumString.new(source.value.to_json)
        when DatumArray
          return DatumString.new(source.value.to_json)
        when DatumNumber
          return DatumString.new(source.value.to_s)
        when DatumBool
          return DatumString.new(source.value.to_s)
        when DatumNull
          return DatumString.new("null")
        end
      when "ARRAY"
        case source
        when DatumObject
          arr = [] of Datum::Type
          source.value.each do |(k, v)|
            arr << [k, v].map &.as(Datum::Type)
          end
          return DatumArray.new(arr)
        end
      when "OBJECT"
        case source
        when DatumArray
          obj = {} of String => Datum::Type
          source.value.each do |pair|
            dpair = Datum.wrap(pair)
            expect_type dpair, DatumArray
            pair = dpair.value
            if pair.size != 2
              raise QueryLogicError.new "Expected array of size 2, but got size #{pair.size}."
            end

            dkey = Datum.wrap(pair[0])
            expect_type dkey, DatumString
            obj[dkey.value] = pair[1]
          end
          return DatumObject.new(obj)
        end
      when "BOOL"
        case source
        when DatumNull
          return DatumBool.new(false)
        when Datum
          return DatumBool.new(true)
        end
      when "NULL"
      else
        raise QueryLogicError.new "Unknown Type: #{target_type}"
      end

      raise QueryLogicError.new "Cannot coerce #{source.class.reql_name} to #{target_type}."
    end
  end
end
