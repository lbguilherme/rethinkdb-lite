module ReQL
  class DatumBinary < Datum
    def self.reql_name
      "BINARY"
    end

    def initialize(@value : Bytes)
    end

    def value
      @value.as(Bytes)
    end
  end
end
