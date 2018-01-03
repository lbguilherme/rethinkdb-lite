module ReQL
  class DatumString < Datum
    def self.reql_name
      "STRING"
    end

    def initialize(@value : String)
    end

    def value
      @value.as(String)
    end
  end
end
