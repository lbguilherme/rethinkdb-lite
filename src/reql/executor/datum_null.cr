module ReQL
  class DatumNull < Datum
    def self.reql_name
      "NULL"
    end

    def initialize
    end

    def value
      nil
    end
  end
end
