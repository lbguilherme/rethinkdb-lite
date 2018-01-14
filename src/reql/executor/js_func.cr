require "../../duktape"

module ReQL
  class JsFunc < Func
    def self.reql_name
      "FUNCTION"
    end

    def initialize(@bytecode : Bytes)
    end

    def eval(evaluator : Evaluator, *args)
      ctx = Duktape::Context.new
      data = LibDuktape.duk_push_buffer_raw(ctx, 0, LibDuktape::DUK_BUF_FLAG_DYNAMIC | LibDuktape::DUK_BUF_FLAG_EXTERNAL)
      LibDuktape.duk_config_buffer(ctx, -1, @bytecode.pointer(1), @bytecode.size)
      LibDuktape.duk_load_function(ctx)
      args.each do |arg|
        ctx.push_datum arg
      end
      LibDuktape.duk_call(ctx, args.size)

      return ctx.get_datum
    end
  end
end
