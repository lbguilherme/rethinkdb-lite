require "../../duktape"

module ReQL
  struct JsFunc < Func
    def reql_type
      "FUNCTION"
    end

    def initialize(@bytecode : Bytes)
    end

    def eval(evaluator : Evaluator, args)
      ctx = Duktape::Context.new
      data = LibDuktape.push_buffer_raw(ctx, 0, LibDuktape::BUF_FLAG_DYNAMIC | LibDuktape::BUF_FLAG_EXTERNAL)
      LibDuktape.config_buffer(ctx, -1, @bytecode.to_unsafe, @bytecode.size)
      LibDuktape.load_function(ctx)
      args.each do |arg|
        ctx.push_datum arg
      end
      LibDuktape.call(ctx, args.size)

      return ctx.get_datum
    end
  end
end
