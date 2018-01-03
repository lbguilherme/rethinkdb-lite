module ReQL
  struct Maxval
  end

  struct Minval
  end

  abstract class Datum
    include Comparable(Datum)

    def self.reql_name
      "DATUM"
    end

    alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | Int32 | String | Nil | Maxval | Minval | Bytes

    def datum
      self
    end

    # Comparison

    def <=>(other)
      a = value
      b = other.value
      cmp_val(a, b)
    end

    def cmp_val(a, b)
      if type_order(a) != type_order(b)
        return type_order(a) <=> type_order(b)
      end

      case a
      when Maxval ; return 0
      when Minval ; return 0
      when Nil    ; return 0
      when Bool   ; return bool_cmp(a, b.as(Bool))
      when String ; return a <=> b.as(String)
      when Float64; return a.to_f64 <=> b.as(Float64 | Int64 | Int32).to_f64
      when Int64  ; return a.to_f64 <=> b.as(Float64 | Int64 | Int32).to_f64
      when Int32  ; return a.to_f64 <=> b.as(Float64 | Int64 | Int32).to_f64
      when Array(Type)
        b = b.as(Array(Type))
        a.each_with_index do |a_val, i|
          return 1 if i >= b.size
          cmp = cmp_val(a_val, b[i])
          return cmp if cmp != 0
        end
        return -1 if b.size > a.size
        return 0
      when Hash(String, Type)
        b = b.as(Hash(String, Type))
        keys_a = a.each_key.to_a.sort
        keys_b = b.each_key.to_a.sort
        keys_a.each_with_index do |ak, i|
          return 1 if i >= keys_b.size
          bk = keys_b[i]
          cmp = cmp_val(ak, bk)
          return cmp if cmp != 0
          av = a[ak]
          bv = b[bk]
          cmp = cmp_val(av, bv)
          return cmp if cmp != 0
        end
        return a.size <=> b.size
      when Bytes
        b = b.as(Bytes)
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

    private def bool_cmp(a, b)
      return 0 if a == b
      return 1 if a && !b
      return -1
    end

    # Serialization

    def serialize
      encode_json_type(value).to_json.to_slice
    end

    def to_json(io)
      encode_json_type(value).to_json(io)
    end

    # def self.unserialize(slice : Bytes)
    #   Datum.wrap(JSON.parse(String.new(slice)))
    # end

    def self.unserialize(io : IO)
      Datum.wrap(decode_json_type(JSON.parse(io).raw))
    end

    private def encode_json_type(val)
      case val
      when Array(Type)
        val.map { |x| encode_json_type(x).as(JSON::Type) }
      when Hash(String, Type)
        hash = {} of String => JSON::Type
        val.each do |(k, v)|
          hash[k] = encode_json_type(v).as(JSON::Type)
        end
        hash
      when Bool
        val
      when Float64
        val
      when Int64
        val
      when Int32
        val.to_i64
      when String
        val
      when Nil
        nil
      when Maxval
        raise QueryLogicError.new "Cannot convert `r.maxval` to JSON"
      when Minval
        raise QueryLogicError.new "Cannot convert `r.minval` to JSON"
      when Bytes
        Hash(String, JSON::Type){
          "$reql_type$" => "BINARY",
          "data"        => Base64.strict_encode(val),
        }
      else
        raise "BUG: encode_json_type"
      end
    end

    protected def self.decode_json_type(val)
      case val
      when Array
        val.map { |x| decode_json_type(x).as(Type) }
      when Hash
        hash = {} of String => Type
        val.each do |(k, v)|
          hash[k] = decode_json_type(v).as(Type)
        end
        hash
      else
        val
      end
    end

    def self.wrap(val)
      val = decode_json_type(val)
      case val
      when Array
        DatumArray.new(val)
      when Hash
        DatumObject.new(val)
      when String
        DatumString.new(val)
      when Int32
        DatumNumber.new(val)
      when Int64
        DatumNumber.new(val)
      when Float64
        DatumNumber.new(val)
      when Bool
        DatumBool.new(val)
      when Bytes
        DatumBinary.new(val)
      when Nil
        DatumNull.new
      when Minval
        DatumMinval.new
      when Maxval
        DatumMaxval.new
      else
        raise "BUG: Datum.wrap"
      end
    end
  end
end
