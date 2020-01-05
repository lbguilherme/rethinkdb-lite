require "./executor/*"
require "./error"
require "./term"
require "./helpers/*"

module ReQL
  class Evaluator
    property vars = {} of Int64 => Datum
    property table_writers = [] of TableWriter

    def initialize(@manager : Storage::Manager)
    end

    def eval(arr : Array)
      Datum.new(arr.map do |e|
        Datum.new(eval(e).value)
      end)
    end

    def eval(hsh : Hash)
      result = {} of String => Datum
      hsh.each do |(k, v)|
        result[k] = Datum.new(eval(v).value)
      end
      Datum.new(result)
    end

    def eval(val : Bool | String | String | Bytes | Float64 | Int64 | Int32 | Nil)
      Datum.new(val)
    end
  end
end

require "./terms/*"
