module ReQL
  struct Maxval
    def to_json(io)
      raise QueryLogicError.new "Cannot convert `r.maxval` to JSON"
    end
  end

  struct Minval
    def to_json(io)
      raise QueryLogicError.new "Cannot convert `r.minval` to JSON"
    end
  end

  class DatumMinval < Datum
    def self.reql_name
      "MINVAL"
    end

    def initialize
    end

    def value
      Minval.new
    end
  end

  class DatumMaxval < Datum
    def self.reql_name
      "MAXVAL"
    end

    def initialize
    end

    def value
      Maxval.new
    end
  end

  class Datum
    def self.wrap(val : Maxval)
      DatumMaxval.new
    end

    def self.wrap(val : Minval)
      DatumMinval.new
    end
  end
end
