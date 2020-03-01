require "./stream"
require "./row_value"
require "../../storage/*"

module ReQL
  struct Table < Stream
    class InternalData
      property channel : Channel(RowValue | Nil | Exception)?
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
      @internal.channel = Channel(RowValue | Nil | Exception).new(32)
      s = storage
      spawn do
        begin
          s.scan do |row|
            @internal.channel.try &.send RowValue.new(s, row)
          end
          @internal.channel.try &.send nil
        rescue Channel::ClosedError
        rescue error
          @internal.channel.try &.send error
        end
      end
    end

    def next_val
      val = @internal.channel.try &.receive?

      case val
      when Nil
        @internal.channel.try &.close
        @internal.channel = nil
      when Exception
        @internal.channel.try &.close
        @internal.channel = nil
        raise val
      else
        val
      end
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
