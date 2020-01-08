require "../term"

module ReQL
  class ObjectTerm < Term
    register_type OBJECT
    prefix_inspect "object"

    def compile
      if @args.size % 2 != 0
        raise QueryLogicError.new "OBJECT expects an even number of arguments (but found #{@args.size})."
      end
    end
  end

  class Evaluator
    def eval(term : ObjectTerm)
      obj = Hash(String, Datum).new

      (term.args.size // 2).times do |i|
        key = eval(term.args[2 * i]).string_value
        value = eval(term.args[2 * i + 1]).as_datum

        if obj.has_key? key
          raise QueryLogicError.new "Duplicate key \"#{key}\" in object.  (got #{obj[key]} and #{value} as values)"
        end

        obj[key] = value
      end

      Datum.new(obj)
    end
  end
end
