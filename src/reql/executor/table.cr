require "./stream"
require "../../storage/*"

module ReQL
  class Table < Stream
    @storage : Storage::AbstractTable?

    def self.reql_name
      "TABLE"
    end

    def initialize(@db : Db?, @name : String)
    end

    private def storage
      x = @storage
      unless x.nil?
        return x
      end
      db_name = @db.try &.name || "test"
      x = @storage = Storage::TableManager.find_table(db_name, @name)
      if x.nil?
        raise OpFailedError.new("Table `#{db_name}.#{@name}` does not exist")
      end
      return x
    end

    def check
      storage
    end

    def get(key : Datum::Type)
      Row.new(storage, key)
    end

    def insert(obj : Datum::Type)
      storage.insert(obj.as(Hash))
    end

    def count(max)
      Math.min(max, storage.count)
    end

    def start_reading
      @channel = Channel(Datum::Type).new
      s = storage
      spawn do
        s.scan do |row|
          if ch = @channel
            ch.send row
          end
        end
        if ch = @channel
          ch.close
        end
        @channel = nil
      end
    end

    def next_val
      begin
        if ch = @channel
          return {ch.receive}
        else
          return nil
        end
      rescue Channel::ClosedError
        return nil
      end
    end

    def finish_reading
      if ch = @channel
        ch.close
      end
      @channel = nil
    end
  end
end
