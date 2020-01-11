require "../term"

module ReQL
  class MergeTerm < Term
    infix_inspect "merge"

    def check
      expect_args 2
    end
  end

  def self.merge_objects(obj1, obj2)
    return obj2 unless obj1.is_a? Hash
    return obj2 unless obj2.is_a? Hash
    obj = obj1.dup
    obj2.each do |(k, v)|
      if obj.has_key? k
        obj[k] = merge_objects(obj[k], v)
      else
        obj[k] = v
      end
    end
    obj
  end

  class Evaluator
    def eval_term(term : MergeTerm)
      target = eval(term.args[0])
      func = eval(term.args[1])

      block = case func
              when Func
                ->(val : Datum) {
                  func.as(Func).eval(self, {val})
                }
              when Datum
                ->(val : Datum) {
                  func
                }
              else
                raise QueryLogicError.new("Expected type FUNCTION but found #{func.reql_type}")
              end

      case
      when target.is_a? Stream
        MapStream.new(target, ->(val : Datum) {
          Datum.new(ReQL.merge_objects(val.hash_value, block.call(val).value))
        })
      when array = target.array_value?
        Datum.new(array.map do |val|
          ReQL.merge_objects(val.hash_value, block.call(val).value)
        end)
      when hash = target.hash_value?
        Datum.new(ReQL.merge_objects(hash, block.call(target.as_datum).value))
      else
        raise QueryLogicError.new("Cannot perform merge on a non-object non-sequence")
      end
    end
  end
end
