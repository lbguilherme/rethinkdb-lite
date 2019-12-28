@[Link(ldflags: "-lduktape -lm")]
lib LibDuktape
  COMPILE_EVAL       = 1u32 << 3  # compile eval code (instead of global code)
  COMPILE_FUNCTION   = 1u32 << 4  # compile function code (instead of global code)
  COMPILE_STRICT     = 1u32 << 5  # use strict (outer) context for global, eval, or function code
  COMPILE_SHEBANG    = 1u32 << 6  # allow shebang ('#! ...') comment on first line of source
  COMPILE_SAFE       = 1u32 << 7  # (internal) catch compilation errors
  COMPILE_NORESULT   = 1u32 << 8  # (internal) omit eval result
  COMPILE_NOSOURCE   = 1u32 << 9  # (internal) no source string on stack
  COMPILE_STRLEN     = 1u32 << 10 # (internal) take strlen() of src_buffer (avoids double evaluation in macro)
  COMPILE_NOFILENAME = 1u32 << 11 # (internal) no filename on stack
  COMPILE_FUNCEXPR   = 1u32 << 12 # (internal) source is a function expression (used for Function constructor)

  TYPE_NONE      = 0 # no value, e.g. invalid index
  TYPE_UNDEFINED = 1 # Ecmascript undefined
  TYPE_NULL      = 2 # Ecmascript null
  TYPE_BOOLEAN   = 3 # Ecmascript boolean: 0 or 1
  TYPE_NUMBER    = 4 # Ecmascript number: double
  TYPE_STRING    = 5 # Ecmascript string: CESU-8 / extended UTF-8 encoded
  TYPE_OBJECT    = 6 # Ecmascript object: includes objects, arrays, functions, threads
  TYPE_BUFFER    = 7 # fixed or dynamic, garbage collected byte buffer
  TYPE_POINTER   = 8 # raw void pointer
  TYPE_LIGHTFUNC = 9 # lightweight function pointer

  BUF_FLAG_DYNAMIC  = 1 << 0 # internal flag: dynamic buffer
  BUF_FLAG_EXTERNAL = 1 << 1 # internal flag: external buffer
  BUF_FLAG_NOZERO   = 1 << 2 # internal flag: don't zero allocated buffer

  fun create_heap = duk_create_heap(alloc_func : (Void*, LibC::SizeT) ->, realloc_func : (Void*, Void*, LibC::SizeT) ->, free_func : (Void*, Void*) ->, heap_udata : Void*, fatal_handler : (Void*, UInt8*) ->) : Void*
  fun eval_raw = duk_eval_raw(ctx : Void*, src_buffer : UInt8*, src_length : LibC::SizeT, flags : UInt32) : Int32
  fun destroy_heap = duk_destroy_heap(ctx : Void*)
  fun dump_function = duk_dump_function(ctx : Void*)
  fun load_function = duk_load_function(ctx : Void*)
  fun is_ecmascript_function = duk_is_ecmascript_function(ctx : Void*, idx : Int32) : Bool
  fun get_type = duk_get_type(ctx : Void*, idx : Int32) : Int32
  fun get_number = duk_get_number(ctx : Void*, idx : Int32) : Float64
  fun get_boolean = duk_get_boolean(ctx : Void*, idx : Int32) : Bool
  fun get_string = duk_get_string(ctx : Void*, idx : Int32) : UInt8*
  fun safe_to_lstring = duk_safe_to_lstring(ctx : Void*, idx : Int32, out_len : LibC::SizeT*) : UInt8*
  fun get_buffer = duk_get_buffer(ctx : Void*, idx : Int32, out_size : LibC::SizeT*) : UInt8*
  fun push_buffer_raw = duk_push_buffer_raw(ctx : Void*, size : LibC::SizeT, flags : UInt32) : UInt8*
  fun call = duk_call(ctx : Void*, nargs : Int32)
  fun config_buffer = duk_config_buffer(ctx : Void*, idx : Int32, ptr : UInt8*, len : LibC::SizeT)
  fun push_number = duk_push_number(ctx : Void*, val : Float64)
  fun push_lstring = duk_push_lstring(ctx : Void*, buffer : UInt8*, len : LibC::SizeT)
end

module Duktape
  class Context
    @ctx : Void*

    def to_unsafe
      @ctx
    end

    def initialize
      @ctx = LibDuktape.create_heap(
        ->(udata, size) { GC.malloc(size) },
        ->(udata, ptr, size) { GC.realloc(ptr, size) },
        ->(udata, ptr) { GC.free(ptr) },
        nil,
        ->(udata, msg) { raise "DUKTAPE FATAL: " + String.new(msg) }
      )
    end

    def finalize
      LibDuktape.destroy_heap(@ctx)
    end

    def get_datum
      case LibDuktape.get_type(@ctx, -1)
      when LibDuktape::TYPE_UNDEFINED
        raise ReQL::QueryLogicError.new "Cannot convert javascript `undefined` to DATUM."
      when LibDuktape::TYPE_NULL
        ReQL::Datum.new(nil)
      when LibDuktape::TYPE_BOOLEAN
        ReQL::Datum.new LibDuktape.get_boolean(@ctx, -1)
      when LibDuktape::TYPE_NUMBER
        ReQL::Datum.new LibDuktape.get_number(@ctx, -1)
      when LibDuktape::TYPE_STRING
        ReQL::Datum.new String.new(LibDuktape.get_string(@ctx, -1))
      when LibDuktape::TYPE_OBJECT
        if LibDuktape.is_ecmascript_function(@ctx, -1)
          LibDuktape.dump_function(@ctx)
          bytes = LibDuktape.get_buffer(@ctx, -1, out bytesize)
          bytecode = Bytes.new(bytesize)
          bytecode.copy_from(Bytes.new(bytes, bytesize))
          ReQL::JsFunc.new bytecode
        else
          raise "TODO: duktape array/object type"
        end
      else
        raise "BUG: Unexpected duktape type: #{LibDuktape.get_type(@ctx, -1)}"
      end
    end

    def push_datum(datum)
      case
      when string = datum.string_value?
        LibDuktape.push_lstring(@ctx, string, string.bytesize)
      when number = datum.number_value?
        LibDuktape.push_number(@ctx, number.to_f64)
      else
        raise "BUG: Unexpected type to push into duktape: #{datum.reql_type}"
      end
    end
  end
end
