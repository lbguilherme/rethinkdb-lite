require "./error"
require "./executor/*"
require "./helpers/*"
require "./term"
require "./worker"

module ReQL
  class Evaluator
    property vars = {} of Int64 => AbstractValue
    property table_writers = [] of TableWriter
    property now = Time.utc

    def initialize(@manager : Storage::Manager, @worker : Worker? = nil)
    end

    def perform_writes
      worker = @worker

      unless worker
        raise QueryLogicError.new "Cannot perform writes on this context."
      end

      writer = TableWriter.new
      @table_writers << writer

      begin
        yield writer, worker
      ensure
        @table_writers.pop
      end

      @table_writers.last?.try &.merge(writer)
      writer.summary
    end

    def eval(hsh : Hash) : AbstractValue
      result = {} of String => Datum
      hsh.each do |(k, v)|
        result[k] = Datum.new(eval(v).value)
      end
      Datum.new(result)
    end

    def eval(val : Bool | String | Bytes | Float64 | Int64 | Int32 | Time | Nil) : AbstractValue
      Datum.new(val)
    end

    def eval(term : Term) : AbstractValue
      term.check
      eval_term(term)
    end

    def eval_term(term : MakeArrayTerm) : AbstractValue
      Datum.new(term.args.map { |arg| eval(arg) })
    end
  end
end

require "./terms/*"
