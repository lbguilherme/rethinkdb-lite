module ReQL
  class DatumObject < Datum
    def self.reql_name
      "OBJECT"
    end

    def initialize(@value : Hash(String, Datum::Type))
    end

    def value
      @value.as(Hash)
    end
  end

  class Datum
    def self.wrap(val : Hash(String, Datum::Type))
      DatumObject.new(val)
    end
  end
end
