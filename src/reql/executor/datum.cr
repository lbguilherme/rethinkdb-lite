module ReQL
  abstract class Datum
    include Comparable(Datum)

    def self.reql_name
      "DATUM"
    end

    alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | Int32 | String | Nil | Maxval | Minval

    def datum
      self
    end

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
      else
        raise "BUG: Missing cmp for #{value.class}"
      end
    end

    private def type_order(value)
      case value
      when Minval               ; 1
      when Array                ; 2
      when Bytes                ; 3
      when Bool                 ; 4
      when Nil                  ; 5
      when Float64, Int32, Int64; 6
      when Hash                 ; 7
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
  end
end
