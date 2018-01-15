module ReQL
  class BracketTerm < Term
    register_type BRACKET

    def inspect(io)
      if @args[0].is_a?(Term)
        @args[0].inspect(io)
      else
        io << "r("
        @args[0].inspect(io)
        io << ")"
      end

      io << "("
      @args[1].inspect(io)
      io << ")"
    end

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : BracketTerm)
      target = eval term.args[0]
      field = eval term.args[1]
      expect_type field, DatumString

      field = field.value

      case target
      when Stream
        MapStream.new(target, ->(val : Datum) {
          case val
          when DatumArray
            raise QueryLogicError.new("Cannot perform bracket on a sequence of sequences")
          when DatumObject
            val = val.value
            if val.has_key? field
              Datum.wrap(val[field])
            else
              raise NonExistenceError.new("No attribute `#{field}` in object: #{JSON.build(4) { |builder| Datum.wrap(val).to_json(builder) }}")
            end
          else
            raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence `#{val.value.inspect}`.")
          end
        })
      when DatumArray
        DatumArray.new(target.value.map { |val|
          case val
          when Array
            raise QueryLogicError.new("Cannot perform bracket on a sequence of sequences")
          when Hash
            if val.has_key? field
              val[field]
            else
              raise NonExistenceError.new("No attribute `#{field}` in object: #{JSON.build(4) { |builder| Datum.wrap(val).to_json(builder) }}")
            end
          else
            raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence `#{val.inspect}`.")
          end
        }.map(&.as(ReQL::Datum::Type)))
      when DatumObject
        target = target.value
        if target.has_key? field
          Datum.wrap(target[field])
        else
          raise NonExistenceError.new("No attribute `#{field}` in object: #{JSON.build(4) { |builder| Datum.wrap(target).to_json(builder) }}")
        end
      else
        raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence `#{target.value.inspect}`.")
      end
    end
  end
end
