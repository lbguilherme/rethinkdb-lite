require "../../duktape"

module ReQL
  class JsFunc < Func
    def self.reql_name
      "FUNCTION"
    end

    def initialize(@bytecode : Bytes)
    end

    def eval(evaluator : Evaluator, *args)
      ctx = LibDuktape.duk_create_heap(nil, nil, nil, nil, ->(data, msg) { raise "DUKTAPE FATAL: " + String.new(msg) })
      data = LibDuktape.duk_push_buffer_raw(ctx, 0, LibDuktape::DUK_BUF_FLAG_DYNAMIC | LibDuktape::DUK_BUF_FLAG_EXTERNAL)
      LibDuktape.duk_config_buffer(ctx, -1, @bytecode.pointer(1), @bytecode.size)
      LibDuktape.duk_load_function(ctx)
      args.each do |arg|
        Duktape.push_value(ctx, arg)
      end
      LibDuktape.duk_call(ctx, args.size)

      return Duktape.get_value(ctx)
    ensure
      LibDuktape.duk_destroy_heap(ctx)
    end
  end
end
