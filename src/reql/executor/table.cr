require "./stream"

module ReQL
  class Table < Stream
    def self.reql_name
      "TABLE"
    end

    def initialize(@table : Storage::Table)
    end

    def get(key : Datum::Type)
      Row.new(@table, key)
    end

    def insert(obj : Datum::Type)
      @table.insert(obj.as(Hash))
    end

    def start_reading
      @channel = Channel(Datum::Type).new
      spawn do
        @table.scan do |row|
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

    def next_row
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
