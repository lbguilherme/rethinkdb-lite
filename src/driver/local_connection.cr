require "socket"
require "../crypto"

module RethinkDB
  class LocalConnection < DriverConnection
    def initialize(data_path : String)
      @config = Storage::Config.new data_path
      @table_manager = Storage::TableManager.new(@config)
    end

    def close
      @config.save
      @table_manager.close_all
    end

    def authorize(user : String, password : String)
    end

    def use(db_name : String)
    end

    def start
    end

    def run(term : ReQL::Term::Type, runopts : Hash)
      evaluator = ReQL::Evaluator.new(@table_manager)
      result = evaluator.eval term

      case result
      when ReQL::Stream
        Cursor.new result
      else
        Datum.new result.value
      end
    end

    class Cursor < RethinkDB::Cursor
      def initialize(@stream : ReQL::Stream)
        @finished = false
        @stream.start_reading
      end

      def next
        return stop if @finished

        val = @stream.next_val

        if val
          Datum.new(val[0])
        else
          @stream.finish_reading
          @finished = true
          stop
        end
      end
    end
  end
end
