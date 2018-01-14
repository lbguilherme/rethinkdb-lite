module ReQL
  class DatumNumber < Datum
    def self.reql_name
      "NUMBER"
    end

    def initialize(@value : Int32 | Int64 | Float64)
      val = @value
      if val.is_a? Float64 && !val.finite?
        if val == Float64::INFINITY
          raise QueryLogicError.new "Non-finite number: inf"
        elsif val == -Float64::INFINITY
          raise QueryLogicError.new "Non-finite number: -inf"
        else
          raise QueryLogicError.new "Non-finite number: #{val}"
        end
      end
    end

    def value
      @value.as(Int32 | Int64 | Float64)
    end

    def to_i64
      case v = value
      when Int32
        v.to_i64
      when Int64
        v
      when Float64
        if v > 2i64**53
          raise ReQL::QueryLogicError.new "Number not an integer (>2^53): #{"%.f" % v}"
        elsif v < -2i64**53
          raise ReQL::QueryLogicError.new "Number not an integer (<-2^53): #{"%.f" % v}"
        elsif v.to_i64 != v
          raise ReQL::QueryLogicError.new "Number not an integer: #{v}"
        else
          v.to_i64
        end
      else
        raise ReQL::QueryLogicError.new "Number not an integer: #{v}"
      end
    end

    def to_f64
      value.to_f64
    end
  end
end
