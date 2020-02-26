require "./abstract_value"
require "../error"
require "json"

module ReQL
  struct Datum < AbstractValue
    property value : AbstractValue::Type

    def initialize(val : Array | Tuple | Set | Hash | Bool | Float64 | Int32 | Int64 | Maxval | Minval | String | Nil | Bytes | JSON::Any | AbstractValue)
      val = val.raw if val.is_a? JSON::Any

      @value = case val
               when AbstractValue
                 val.value
               when Set(Datum)
                 val
               when Array, Set
                 val.map { |e| Datum.new(e).as(Datum) }
               when Tuple
                 val.map { |e| Datum.new(e).as(Datum) }.to_a
               when Float64
                 if !val.finite?
                   if val == Float64::INFINITY
                     raise QueryLogicError.new "Non-finite number: inf"
                   elsif val == -Float64::INFINITY
                     raise QueryLogicError.new "Non-finite number: -inf"
                   else
                     raise QueryLogicError.new "Non-finite number: #{val}"
                   end
                 end
                 val
               when Hash
                 if val["$reql_type$"]? == "BINARY"
                   unless val.has_key? "data"
                     raise QueryLogicError.new "Invalid binary pseudotype: lacking `data` key."
                   end
                   extra_keys = val.keys - ["$reql_type$", "data"]
                   if extra_keys.size > 0
                     raise QueryLogicError.new "Invalid binary pseudotype: illegal `#{extra_keys[0]}` key."
                   end
                   Base64.decode(Datum.new(val["data"]).string_value)
                 else
                   hash = {} of String => Datum
                   val.each do |(k, v)|
                     hash[k] = Datum.new(v)
                   end
                   hash
                 end
               else
                 val
               end
    end

    def reql_type
      case value
      when Array, Set
        "ARRAY"
      when Hash
        "OBJECT"
      when String
        "STRING"
      when Int32, Int64, Float64
        "NUMBER"
      when Nil
        "NULL"
      when Maxval
        "MAXVAL"
      when Minval
        "MINVAL"
      when Bool
        "BOOL"
      when Bytes
        "BINARY"
      end
    end

    def as_datum
      self
    end

    def inspect(io)
      value.inspect(io)
    end

    def self.unserialize(io : IO)
      Datum.new(JSON.parse(io))
    end

    def as_database
      raise QueryLogicError.new("Expected type DATABASE but found DATUM.")
    end

    def as_function
      if (str = @value).is_a? String
        FieldFunc.new(str)
      else
        raise QueryLogicError.new("Expected type FUNCTION but found DATUM.")
      end
    end

    def as_table
      raise QueryLogicError.new("Expected type TABLE but found DATUM.")
    end

    def as_row
      raise QueryLogicError.new("Expected type ROW but found DATUM.")
    end
  end
end
