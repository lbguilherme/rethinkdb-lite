module ReQL
  abstract class Datum
    def self.reql_name
      "DATUM"
    end

    alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | Int32 | String | Nil

    def datum
      self
    end
  end
end
