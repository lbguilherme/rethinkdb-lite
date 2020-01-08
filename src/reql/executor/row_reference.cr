require "./row"

module ReQL
  struct RowReference < Row
    @key : Box(Datum)

    def initialize(table : Storage::AbstractTable, key : Datum)
      super(table)
      @key = Box(Datum).new(key)
    end

    def value : Type
      @table.get(@key.object)
    end

    def key : Datum
      @key.object
    end
  end
end
