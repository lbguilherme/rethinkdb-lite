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

  class Datum
    def self.wrap(val : Nil)
      DatumNull.new
    end
  end
end
