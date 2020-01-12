require "./stream"
require "./row_value"
require "../../storage/*"

module ReQL
  struct Table < Stream
    class InternalData
      property channel : Channel(RowValue?)?
    end

    def reql_type
      "TABLE"
    end

    property name
    property db

    def initialize(@db : Db, @name : String, @manager : Storage::Manager)
      @internal = InternalData.new
    end

    def storage
      result = @manager.get_table(@db.name, @name)
      if result.nil?
        raise OpFailedError.new("Table `#{@db.name}.#{@name}` does not exist")
      end
      result
    end

    def get(key : Datum)
      RowReference.new(storage, key)
    end

    def start_reading
      @internal.channel = Channel(RowValue?).new(32)
      s = storage
      spawn do
        begin
          s.scan do |row|
            @internal.channel.try &.send RowValue.new(s, row)
          end
          @internal.channel.try &.send nil
        rescue Channel::ClosedError
        end
      end
    end

    def next_val
      val = @internal.channel.try &.receive?
      unless val
        @internal.channel.try &.close
        @internal.channel = nil
      end
      val
    end

    def finish_reading
      @internal.channel.try &.close
      @internal.channel = nil
    end

    def as_table
      self
    end
  end
end
