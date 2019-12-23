module ReQL
  struct Maxval
  end

  struct Minval
  end

  abstract struct AbstractValue
    include Comparable(Object)

    alias Type = Array(Datum) | Bool | Float64 | Hash(String, Datum) | Int64 | Int32 | String | Nil | Maxval | Minval | Bytes

    # Comparison

    def <=>(other : AbstractValue)
      self <=> other.value
    end

    def <=>(other)
      a = value
      b = other

      if type_order(a) != type_order(b)
        return type_order(a) <=> type_order(b)
      end

      case {a, b}
      when {Maxval, Maxval}  ; return 0
      when {Minval, Minval}  ; return 0
      when {Nil, Nil}        ; return 0
      when {String, String}  ; return a <=> b
      when {Float64, Float64}; return a <=> b
      when {Float64, Int64}  ; return a <=> b.to_f64
      when {Float64, Int32}  ; return a <=> b.to_f64
      when {Int64, Float64}  ; return a.to_f64 <=> b
      when {Int64, Int64}    ; return a <=> b
      when {Int64, Int32}    ; return a <=> b.to_i64
      when {Int32, Float64}  ; return a.to_f64 <=> b
      when {Int32, Int64}    ; return a.to_i64 <=> b
      when {Int32, Int32}    ; return a <=> b
      when {Bool, Bool}
        return 0 if a == b
        return 1 if a && !b
        return -1
      when {Array, Array}
        a.each_with_index do |a_val, i|
          return 1 if i >= b.size
          cmp = a_val <=> b[i]
          return cmp if cmp != 0
        end
        return -1 if b.size > a.size
        return 0
      when {Hash, Hash}
        keys_a = a.each_key.to_a.sort
        keys_b = b.each_key.to_a.sort
        keys_a.each_with_index do |ak, i|
          return 1 if i >= keys_b.size
          bk = keys_b[i]
          cmp = ak <=> bk
          return cmp if cmp != 0
          av = a[ak]
          bv = b[bk]
          cmp = av <=> bv
          return cmp if cmp != 0
        end
        return a.size <=> b.size
      when {Bytes, Bytes}
        a.each_with_index do |a_val, i|
          return 1 if i >= b.size
          cmp = a_val <=> b[i]
          return cmp if cmp != 0
        end
        return -1 if b.size > a.size
        return 0
      else
        raise "BUG: Missing cmp for #{value.class}"
      end
    end

    private def type_order(value)
      case value
      when Minval               ; 1
      when Array                ; 2
      when Bool                 ; 3
      when Nil                  ; 4
      when Float64, Int32, Int64; 5
      when Hash                 ; 6
      when Bytes                ; 7
      when String               ; 8
      when Maxval               ; 9
      else
        raise "BUG: Missing order for #{value.class}"
      end
    end

    # Serialization

    def serialize
      encode_as_json(value).to_json.to_slice
    end

    def to_json(io)
      encode_as_json(value).to_json(io)
    end

    private def encode_as_json(val : Type)
      case val
      when Array
        JSON::Any.new(val.map { |x| encode_as_json(x.value).as(JSON::Any) })
      when Hash
        hash = {} of String => JSON::Any
        val.each do |(k, v)|
          hash[k] = encode_as_json(v.value)
        end
        JSON::Any.new(hash)
      when Maxval
        raise QueryLogicError.new "Cannot convert `r.maxval` to JSON"
      when Minval
        raise QueryLogicError.new "Cannot convert `r.minval` to JSON"
      when Bytes
        JSON::Any.new({
          "$reql_type$" => JSON::Any.new("BINARY"),
          "data"        => JSON::Any.new(Base64.strict_encode(val)),
        })
      when Int32
        JSON::Any.new(val.to_i64)
      when Bool, Float64, Int64, String, Nil
        JSON::Any.new(val)
      else
        raise "BUG: encode_as_json"
      end
    end

    def each
      array = array_value?

      unless array
        raise QueryLogicError.new("Cannot convert #{reql_type} to SEQUENCE")
      end

      array.each { |val| yield val }
    end

    macro value_cast(method_name, type, expected_reql_type)
      def {{"#{method_name.id}_value".id}}
        unless {{"is_#{method_name.id}?".id}}
          raise QueryLogicError.new("Expected type #{{{expected_reql_type}}} but found #{reql_type}.")
        end

        value.as({{type}})
      end

      def {{"#{method_name.id}_value?".id}}
        unless {{"is_#{method_name.id}?".id}}
          return nil
        end

        value.as({{type}})
      end

      def {{"#{method_name.id}_or_nil_value".id}}
        if reql_type == "NULL"
          return nil
        end

        unless {{"is_#{method_name.id}?".id}}
          raise QueryLogicError.new("Expected type #{{{expected_reql_type}}} but found #{reql_type}.")
        end

        value.as({{type}})
      end

      def {{"is_#{method_name.id}?".id}}
        reql_type == {{expected_reql_type}}
      end
    end

    value_cast(string, String, "STRING")
    value_cast(hash, Hash, "OBJECT")
    value_cast(array, Array, "ARRAY")
    value_cast(bytes, Bytes, "BINARY")
    value_cast(bool, Bool, "BOOL")
    value_cast(number, Int32 | Int64 | Float64, "NUMBER")

    def is_array?
      {"ARRAY", "STREAM", "TABLE"}.includes? reql_type
    end

    def is_hash?
      {"OBJECT", "ROW"}.includes? reql_type
    end

    def int64_value
      case v = number_value
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

    def as_datum
      Datum.new(value)
    end

    def as_database
      raise QueryLogicError.new("Expected type DATABASE but found #{reql_type}.")
    end

    def as_function
      raise QueryLogicError.new("Expected type FUNCTION but found #{reql_type}.")
    end

    def as_table
      raise QueryLogicError.new("Expected type TABLE but found #{reql_type}.")
    end
  end
end

struct Int32
  include Comparable(ReQL::AbstractValue)

  def <=>(other : ReQL::AbstractValue)
    res = (other <=> self)
    -res if res
  end
end

struct Int64
  include Comparable(ReQL::AbstractValue)

  def <=>(other : ReQL::AbstractValue)
    res = (other <=> self)
    -res if res
  end
end

struct Float64
  include Comparable(ReQL::AbstractValue)

  def <=>(other : ReQL::AbstractValue)
    res = (other <=> self)
    -res if res
  end
end

class String
  include Comparable(ReQL::AbstractValue)

  def <=>(other : ReQL::AbstractValue)
    res = (other <=> self)
    -res if res
  end
end

class Array(T)
  include Comparable(ReQL::AbstractValue)

  def <=>(other : ReQL::AbstractValue)
    res = (other <=> self)
    -res if res
  end

  def ==(other : ReQL::AbstractValue)
    other == self
  end
end

class Hash(K, V)
  include Comparable(ReQL::AbstractValue)

  def <=>(other : ReQL::AbstractValue)
    res = (other <=> self)
    -res if res
  end

  def ==(other : ReQL::AbstractValue)
    other == self
  end
end
