require "./stream"
require "../../storage/*"

module ReQL
  struct Table < Stream
    class InternalData
      property channel : Channel(Row)?
    end

    def reql_type
      "TABLE"
    end

    def initialize(@db : Db?, @name : String, @manager : Storage::Manager)
      @internal = InternalData.new
    end

    private def storage
      db_name = @db.try &.name || "test"
      result = @manager.get_table(db_name, @name)
      if result.nil?
        raise OpFailedError.new("Table `#{db_name}.#{@name}` does not exist")
      end
      result
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
      @internal.channel = Channel(Row).new
      s = storage
      spawn do
        begin
          s.scan do |row|
            if ch = @internal.channel
              ch.send Row.new(s, row[s.primary_key], row)
            end
          end
          if ch = @internal.channel
            ch.close
          end
          @internal.channel = nil
        rescue Channel::ClosedError
        end
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
