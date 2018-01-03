module ReQL
  class DatumArray < Datum
    def self.reql_name
      "ARRAY"
    end

    def initialize(@value : Array(Datum::Type))
    end

    def value
      @value.as(Array)
    end
  end
end
