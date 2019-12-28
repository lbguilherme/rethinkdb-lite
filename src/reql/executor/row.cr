require "./abstract_value"

module ReQL
  struct Row < AbstractValue
    def reql_type
      "ROW"
    end

    @key : Box(Datum)
    @value : Box(Hash(String, ReQL::Datum)?)

    def initialize(@table : Storage::AbstractTable, key : Datum, value : Hash(String, ReQL::Datum)? = nil)
      @key = Box(Datum).new(key)
      @value = Box(Hash(String, ReQL::Datum)?).new(value)
    end

    def value : Type
      obj = @value.object
      if obj.nil?
        val = @table.get(@key.object)
        @value = Box(Hash(String, ReQL::Datum)?).new(val)
        val
      else
        obj
      end
    end

    def as_row
      self
    end

    def key
      @key.object
    end

    def table
      @table
    end
  end
end
