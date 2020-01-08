require "socket"
require "../crypto"
require "../storage/manager"
require "../reql/evaluator"
require "./connection"

module RethinkDB
  class LocalConnection < Connection
    def initialize(data_path : String)
      @manager = Storage::Manager.new data_path
    end

    def close
      @manager.close
    end

    def authorize(user : String, password : String)
    end

    def use(db_name : String)
    end

    def start
    end

    def run(term : ReQL::Term::Type, runopts : RunOpts) : RethinkDB::Cursor | RethinkDB::Datum
      evaluator = ReQL::Evaluator.new(@manager)
      result = evaluator.eval term

      case result
      when ReQL::Stream
        Cursor.new result, runopts
      else
        Datum.new result.value, runopts
      end
    end

    def server : JSON::Any
      JSON::Any.new(Hash{
        "id"    => JSON::Any.new(@manager.system_info.id.to_s),
        "name"  => JSON::Any.new(@manager.system_info.name),
        "proxy" => JSON::Any.new(false),
      }.as(JSON::Any::Type))
    end

    class Cursor < RethinkDB::Cursor
      def initialize(@stream : ReQL::Stream, @runopts : RunOpts)
        @finished = false
        @stream.start_reading
      end

      def next
        return stop if @finished

        val = @stream.next_val

        if val
          Datum.new val.as_datum, @runopts
        else
          @stream.finish_reading
          @finished = true
          stop
        end
      end

      def close
        unless @finished
          @finished = true
          @stream.finish_reading
        end
      end
    end
  end
end
