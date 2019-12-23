{% begin %}
  @[Link(ldflags: "-lduktape -lm")]
{% end %}
lib LibDuktape
  DUK_COMPILE_EVAL       = 1u32 << 3  # compile eval code (instead of global code)
  DUK_COMPILE_FUNCTION   = 1u32 << 4  # compile function code (instead of global code)
  DUK_COMPILE_STRICT     = 1u32 << 5  # use strict (outer) context for global, eval, or function code
  DUK_COMPILE_SHEBANG    = 1u32 << 6  # allow shebang ('#! ...') comment on first line of source
  DUK_COMPILE_SAFE       = 1u32 << 7  # (internal) catch compilation errors
  DUK_COMPILE_NORESULT   = 1u32 << 8  # (internal) omit eval result
  DUK_COMPILE_NOSOURCE   = 1u32 << 9  # (internal) no source string on stack
  DUK_COMPILE_STRLEN     = 1u32 << 10 # (internal) take strlen() of src_buffer (avoids double evaluation in macro)
  DUK_COMPILE_NOFILENAME = 1u32 << 11 # (internal) no filename on stack
  DUK_COMPILE_FUNCEXPR   = 1u32 << 12 # (internal) source is a function expression (used for Function constructor)

  DUK_TYPE_NONE      = 0 # no value, e.g. invalid index
  DUK_TYPE_UNDEFINED = 1 # Ecmascript undefined
  DUK_TYPE_NULL      = 2 # Ecmascript null
  DUK_TYPE_BOOLEAN   = 3 # Ecmascript boolean: 0 or 1
  DUK_TYPE_NUMBER    = 4 # Ecmascript number: double
  DUK_TYPE_STRING    = 5 # Ecmascript string: CESU-8 / extended UTF-8 encoded
  DUK_TYPE_OBJECT    = 6 # Ecmascript object: includes objects, arrays, functions, threads
  DUK_TYPE_BUFFER    = 7 # fixed or dynamic, garbage collected byte buffer
  DUK_TYPE_POINTER   = 8 # raw void pointer
  DUK_TYPE_LIGHTFUNC = 9 # lightweight function pointer

  DUK_BUF_FLAG_DYNAMIC  = 1 << 0 # internal flag: dynamic buffer
  DUK_BUF_FLAG_EXTERNAL = 1 << 1 # internal flag: external buffer
  DUK_BUF_FLAG_NOZERO   = 1 << 2 # internal flag: don't zero allocated buffer

  fun duk_create_heap(alloc_func : (Void*, LibC::SizeT) ->, realloc_func : (Void*, Void*, LibC::SizeT) ->, free_func : (Void*, Void*) ->, heap_udata : Void*, fatal_handler : (Void*, UInt8*) ->) : Void*
  fun duk_eval_raw(ctx : Void*, src_buffer : UInt8*, src_length : LibC::SizeT, flags : UInt32) : Int32
  fun duk_destroy_heap(ctx : Void*)
  fun duk_dump_function(ctx : Void*)
  fun duk_load_function(ctx : Void*)
  fun duk_is_ecmascript_function(ctx : Void*, idx : Int32) : Bool
  fun duk_get_type(ctx : Void*, idx : Int32) : Int32
  fun duk_get_number(ctx : Void*, idx : Int32) : Float64
  fun duk_get_boolean(ctx : Void*, idx : Int32) : Bool
  fun duk_get_string(ctx : Void*, idx : Int32) : UInt8*
  fun duk_safe_to_lstring(ctx : Void*, idx : Int32, out_len : LibC::SizeT*) : UInt8*
  fun duk_get_buffer(ctx : Void*, idx : Int32, out_size : LibC::SizeT*) : UInt8*
  fun duk_push_buffer_raw(ctx : Void*, size : LibC::SizeT, flags : UInt32) : UInt8*
  fun duk_call(ctx : Void*, nargs : Int32)
  fun duk_config_buffer(ctx : Void*, idx : Int32, ptr : UInt8*, len : LibC::SizeT)
  fun duk_push_number(ctx : Void*, val : Float64)
  fun duk_push_lstring(ctx : Void*, buffer : UInt8*, len : LibC::SizeT)
end

module Duktape
  class Context
    @ctx : Void*

    def to_unsafe
      @ctx
    end

    def initialize
      @ctx = LibDuktape.duk_create_heap(
        ->(udata, size) { GC.malloc(size) },
        ->(udata, ptr, size) { GC.realloc(ptr, size) },
        ->(udata, ptr) { GC.free(ptr) },
        nil,
        ->(udata, msg) { raise "DUKTAPE FATAL: " + String.new(msg) }
      )
    end

    def finalize
      LibDuktape.duk_destroy_heap(@ctx)
    end

    def get_datum
      case LibDuktape.duk_get_type(@ctx, -1)
      when LibDuktape::DUK_TYPE_UNDEFINED
        raise ReQL::QueryLogicError.new "Cannot convert javascript `undefined` to DATUM."
      when LibDuktape::DUK_TYPE_NULL
        ReQL::Datum.new(nil)
      when LibDuktape::DUK_TYPE_BOOLEAN
        ReQL::Datum.new LibDuktape.duk_get_boolean(@ctx, -1)
      when LibDuktape::DUK_TYPE_NUMBER
        ReQL::Datum.new LibDuktape.duk_get_number(@ctx, -1)
      when LibDuktape::DUK_TYPE_STRING
        ReQL::Datum.new String.new(LibDuktape.duk_get_string(@ctx, -1))
      when LibDuktape::DUK_TYPE_OBJECT
        if LibDuktape.duk_is_ecmascript_function(@ctx, -1)
          LibDuktape.duk_dump_function(@ctx)
          bytes = LibDuktape.duk_get_buffer(@ctx, -1, out bytesize)
          bytecode = Bytes.new(bytesize)
          bytecode.copy_from(Bytes.new(bytes, bytesize))
          ReQL::JsFunc.new bytecode
        else
          raise "TODO: duktape array/object type"
        end
      else
        raise "BUG: Unexpected duktape type: #{LibDuktape.duk_get_type(@ctx, -1)}"
      end
    end

    def push_datum(datum)
      case
      when string = datum.string_value?
        LibDuktape.duk_push_lstring(@ctx, string, string.bytesize)
      when number = datum.number_value?
        LibDuktape.duk_push_number(@ctx, number.to_f64)
      else
        raise "BUG: Unexpected type to push into duktape: #{datum.reql_type}"
      end
    end
  end
end
