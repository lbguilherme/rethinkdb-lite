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
      target = eval(term.args[0])
      field = eval(term.args[1]).string_value

      case
      when target.is_a? Stream
        MapStream.new(target, ->(val : Datum) {
          case
          when val.is_array?
            raise QueryLogicError.new("Cannot perform bracket on a sequence of sequences")
          when inner_hash = val.hash_value?
            if inner_hash.has_key? field
              inner_hash[field]
            else
              raise NonExistenceError.new("No attribute `#{field}` in object: #{JSON.build(4) { |builder| inner_hash.to_json(builder) }}")
            end
          else
            raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence `#{val.value.inspect}`.")
          end
        })
      when array = target.array_value?
        Datum.new(array.map { |val|
          case
          when val.is_array?
            raise QueryLogicError.new("Cannot perform bracket on a sequence of sequences")
          when inner_hash = val.hash_value?
            if inner_hash.has_key? field
              inner_hash[field]
            else
              raise NonExistenceError.new("No attribute `#{field}` in object: #{JSON.build(4) { |builder| inner_hash.to_json(builder) }}")
            end
          else
            raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence `#{val.value.inspect}`.")
          end
        }.map(&.as(ReQL::Datum)))
      when hash = target.hash_value?
        if hash.has_key? field
          Datum.new(hash[field])
        else
          raise NonExistenceError.new("No attribute `#{field}` in object: #{JSON.build(4) { |builder| hash.to_json(builder) }}")
        end
      else
        raise QueryLogicError.new("Cannot perform bracket on a non-object non-sequence `#{target.inspect}`.")
      end
    end
  end
end
