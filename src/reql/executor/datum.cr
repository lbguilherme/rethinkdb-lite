module ReQL
  class Datum
    def self.reql_name
      "DATUM"
    end

    alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | Int32 | String | Nil

    def initialize(@value : Type)
    end

    def value
      @value
    end

    def self.wrap(val : Bool | Float64 | Int64 | Int32 | Nil)
      Datum.new(val)
    end

    def datum
      self
    end
  end
end
