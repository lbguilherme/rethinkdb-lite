require "../term"

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
      source = eval(term.args[0])
      target_type = eval(term.args[1]).string_value.upcase
      source = source.as_datum

      if source.reql_type == target_type
        return source
      end

      case target_type
      when "NUMBER"
        if string = source.string_value?
          begin
            return Datum.new(string.to_f64)
          rescue ex : ArgumentError
            raise QueryLogicError.new "Could not coerce `#{source.value}` to NUMBER."
          end
        end
      when "STRING"
        case
        when hash = source.hash_value?
          return Datum.new(hash.to_json)
        when array = source.array_value?
          return Datum.new(array.to_json)
        when number = source.number_value?
          return Datum.new(number.to_s)
        when (bool = source.bool_value?) != nil
          return Datum.new(bool.to_s)
        when source.value == nil
          return Datum.new("null")
        end
      when "ARRAY"
        if hash = source.hash_value?
          return Datum.new(hash.each.to_a)
        end
      when "OBJECT"
        case
        when array = source.array_value?
          obj = {} of String => Datum
          array.each do |pair|
            pair = pair.array_value
            if pair.size != 2
              raise QueryLogicError.new "Expected array of size 2, but got size #{pair.size}."
            end

            obj[pair[0].string_value] = pair[1]
          end
          return Datum.new(obj)
        end
      when "BOOL"
        return Datum.new(source.value != nil)
      when "NULL"
      else
        raise QueryLogicError.new "Unknown Type: #{target_type}"
      end

      raise QueryLogicError.new "Cannot coerce #{source.reql_type} to #{target_type}."
    end
  end
end
