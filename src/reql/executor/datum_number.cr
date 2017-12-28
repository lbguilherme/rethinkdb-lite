module ReQL
  class DatumNumber < Datum
    def self.reql_name
      "NUMBER"
    end

    def initialize(@value : Int32 | Int64 | Float64)
    end

    def value
      @value.as(Int32 | Int64 | Float64)
    end
  end

  class Datum
    def self.wrap(val : Int32 | Int64 | Float64)
      DatumNumber.new(val)
    end
  end
end
