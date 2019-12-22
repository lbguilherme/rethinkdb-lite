require "./stream"
require "../../storage/*"

module ReQL
  struct Table < Stream
    @storage : Storage::AbstractTable?

    class InternalData
      property channel : Channel(Datum)?
    end

    def reql_type
      "TABLE"
    end

    def initialize(@db : Db?, @name : String, @table_manager : Storage::TableManager)
      @internal = InternalData.new
    end

    private def storage
      x = @storage
      unless x.nil?
        return x
      end
      db_name = @db.try &.name || "test"
      x = @storage = @table_manager.find_table(db_name, @name)
      if x.nil?
        raise OpFailedError.new("Table `#{db_name}.#{@name}` does not exist")
      end
      return x
    end

    def check
      storage
      nil
    end

    def get(key : Datum)
      Row.new(storage, key)
    end

    def insert(obj : Hash)
      storage.insert(obj)
    end

    def count(max)
      Math.min(max, storage.count)
    end

    def start_reading
      @internal.channel = Channel(Datum).new
      s = storage
      spawn do
        s.scan do |row|
          if ch = @internal.channel
            ch.send Datum.new(row)
          end
        end
        if ch = @internal.channel
          ch.close
        end
        @internal.channel = nil
      end
    end

    def next_val
      begin
        if ch = @internal.channel
          return ch.receive
        else
          return nil
        end
      rescue Channel::ClosedError
        return nil
      end
    end

    def finish_reading
      if ch = @internal.channel
        ch.close
      end
      @internal.channel = nil
    end

    def as_table
      self
    end
  end
end
