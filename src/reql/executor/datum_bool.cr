module ReQL
  class DatumBool < Datum
    def self.reql_name
      "BOOL"
    end

    def initialize(@value : Bool)
    end

    def value
      @value.as(Bool)
    end
  end
end
