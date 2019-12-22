require "./abstract_value"

module ReQL
  struct Row < AbstractValue
    def reql_type
      "ROW"
    end

    @key : Box(AbstractValue)

    def initialize(@table : Storage::AbstractTable, key : AbstractValue)
      @key = Box(AbstractValue).new(key)
    end

    def value
      @table.get(@key.object)
    end
  end
end
