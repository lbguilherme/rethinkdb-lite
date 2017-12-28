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
      obj = Hash(String, Datum::Type).new

      (term.args.size / 2).times do |i|
        k = eval term.args[2*i]
        expect_type k, DatumString
        k = k.value

        v = eval term.args[2*i + 1]
        expect_type v, Datum

        if obj.has_key? k
          raise QueryLogicError.new "Duplicate key \"#{k}\" in object.  (got #{obj[k]} and #{v.value} as values)"
        end

        obj[k] = v.value
      end

      Datum.wrap(obj)
    end
  end
end
