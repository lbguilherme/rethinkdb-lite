require "./stream"

module ReQL
  class Db
    getter name

    def self.reql_name
      "DB"
    end

    def initialize(@name : String)
    end

    def value
      raise RuntimeError.new "Query result must be of type DATUM, GROUPED_DATA, or STREAM (got DATABASE)"
    end

    def datum
      raise RuntimeError.new "Query result must be of type DATUM, GROUPED_DATA, or STREAM (got DATABASE)"
    end
  end
end
