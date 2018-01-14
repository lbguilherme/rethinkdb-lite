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

      ctx = Duktape::Context.new

      flags = LibDuktape::DUK_COMPILE_EVAL | LibDuktape::DUK_COMPILE_NOSOURCE | LibDuktape::DUK_COMPILE_NOFILENAME | LibDuktape::DUK_COMPILE_SAFE
      if LibDuktape.duk_eval_raw(ctx, code, code.bytesize, flags) != 0
        raise QueryLogicError.new String.new(LibDuktape.duk_safe_to_lstring(ctx, -1, nil))
      end

      return ctx.get_datum
    end
  end
end
