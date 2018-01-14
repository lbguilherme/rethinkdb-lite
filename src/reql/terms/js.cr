require "../../duktape"

module ReQL
  class JsTerm < Term
    register_type JAVASCRIPT
    prefix_inspect "js"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : JsTerm)
      code = eval term.args[0]
      expect_type code, DatumString
      code = code.value

      ctx = LibDuktape.duk_create_heap(nil, nil, nil, nil, ->(data, msg) { raise "DUKTAPE FATAL: " + String.new(msg) })
      unless ctx
        # TODO
        raise "BUG: Failed to initialize JS context"
      end

      flags = LibDuktape::DUK_COMPILE_EVAL | LibDuktape::DUK_COMPILE_NOSOURCE | LibDuktape::DUK_COMPILE_NOFILENAME | LibDuktape::DUK_COMPILE_SAFE
      if LibDuktape.duk_eval_raw(ctx, code, code.bytesize, flags) != 0
        raise QueryLogicError.new String.new(LibDuktape.duk_safe_to_lstring(ctx, -1, nil))
      end

      return Duktape.get_value(ctx)
    ensure
      LibDuktape.duk_destroy_heap(ctx)
    end
  end
end
