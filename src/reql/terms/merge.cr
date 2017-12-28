module ReQL
  class MergeTerm < Term
    register_type MERGE
    infix_inspect "merge"

    def compile
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
    obj.as(Datum::Type)
  end

  class Evaluator
    def eval(term : MergeTerm)
      target = eval term.args[0]
      func = eval term.args[1]

      block = case func
              when Func
                ->(val : Datum) {
                  func.as(Func).eval(self, val).datum
                }
              when Datum
                ->(val : Datum) {
                  func
                }
              else
                raise QueryLogicError.new("Expected type FUNCTION but found #{func.class.reql_name}")
              end

      case target
      when Stream
        MapStream.new(target, ->(val : Datum) {
          expect_type val, DatumObject
          Datum.wrap(ReQL.merge_objects(val.value, block.call(val).value))
        })
      when DatumArray
        DatumArray.new(target.value.map do |val|
          val = Datum.wrap(val)
          expect_type val, DatumObject
          ReQL.merge_objects(val.value, block.call(val).value).as(Datum::Type)
        end)
      when DatumObject
        obj1 = target.value
        Datum.wrap(ReQL.merge_objects(obj1, block.call(Datum.wrap(obj1)).value))
      else
        raise QueryLogicError.new("Cannot perform merge on a non-object non-sequence")
      end
    end
  end
end
