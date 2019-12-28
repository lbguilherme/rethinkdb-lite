require "./abstract_value"

module ReQL
  struct RowValue < Row
    @value : Box(Hash(String, ReQL::Datum))

    def initialize(table : Storage::AbstractTable, value : Hash(String, ReQL::Datum))
      super(table)
      @value = Box(Hash(String, ReQL::Datum)).new(value)
    end

    def value : Type
      @value.object
    end

    def key : Datum
      @value.object[@table.primary_key]
    end
  end
end
