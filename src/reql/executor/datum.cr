module ReQL
  class Datum
    def self.reql_name
      "DATUM"
    end

    alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | String | Nil

    def initialize(@value : Type)
    end

    def value
      @value
    end

    def self.wrap(val : Bool | Float64 | Hash(String, Type) | Int64 | Nil)
      Datum.new(val)
    end
  end
end
