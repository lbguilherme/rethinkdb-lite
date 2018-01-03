module ReQL
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
end
