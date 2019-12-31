require "./executor/datum.cr"

module ReQL
  def self.encode_key(datum : Datum)
    io = IO::Memory.new
    encode_key(io, datum)
    io.to_slice
  end

  def self.decode_key(bytes : Bytes)
    io = IO::Memory.new(bytes, false)
    decode_key(io)
  end
end

private BYTE_MINVAL          = 0x01u8
private BYTE_ARRAY           = 0x10u8
private BYTE_FALSE           = 0x20u8
private BYTE_TRUE            = 0x30u8
private BYTE_NULL            = 0x40u8
private BYTE_DOUBLE_NEGATIVE = 0x50u8
private BYTE_DOUBLE_POSITIVE = 0x51u8
private BYTE_OBJECT          = 0x60u8
private BYTE_BYTES           = 0x70u8
private BYTE_STRING          = 0x80u8
private BYTE_MAXVAL          = 0xFEu8
private BYTE_END             = 0x00u8

private def decode_key(io)
  case io.read_byte
  when BYTE_MINVAL
    ReQL::Datum.new(ReQL::Minval.new)
  when BYTE_MAXVAL
    ReQL::Datum.new(ReQL::Maxval.new)
  when BYTE_TRUE
    ReQL::Datum.new(true)
  when BYTE_FALSE
    ReQL::Datum.new(false)
  when BYTE_NULL
    ReQL::Datum.new(nil)
  when BYTE_DOUBLE_NEGATIVE
    bytes = Bytes.new(8)
    io.read_fully(bytes)
    bytes.map! { |byte| byte ^ 0xffu8 }
    num = -IO::ByteFormat::BigEndian.decode(Float64, bytes)
    ReQL::Datum.new(num)
  when BYTE_DOUBLE_POSITIVE
    bytes = Bytes.new(8)
    io.read_fully(bytes)
    bytes[0] ^= 0x80u8
    num = IO::ByteFormat::BigEndian.decode(Float64, bytes)
    ReQL::Datum.new(num)
  when BYTE_ARRAY
    arr = [] of ReQL::Datum
    while io.peek.not_nil![0] != BYTE_END
      arr << decode_key(io)
    end
    io.read_byte
    ReQL::Datum.new(arr)
  when BYTE_OBJECT
    hsh = {} of String => ReQL::Datum
    while io.peek.not_nil![0] != BYTE_END
      k = io.gets('\0', true).not_nil!
      hsh[k] = decode_key(io)
    end
    io.read_byte
    ReQL::Datum.new(hsh)
  when BYTE_STRING
    ReQL::Datum.new(io.gets('\0', true).not_nil!)
  when BYTE_BYTES
    ReQL::Datum.new(Base64.decode(io.gets('\0', true).not_nil!))
  else
    raise "BUG: Unexpected byte at decode_key"
  end
end

private def encode_key(io, datum : ReQL::Datum)
  encode_key(io, datum.value)
end

private def encode_key(io, maxval : ReQL::Minval)
  io.write_byte(BYTE_MINVAL)
end

private def encode_key(io, maxval : ReQL::Maxval)
  io.write_byte(BYTE_MAXVAL)
end

private def encode_key(io, x : Nil)
  io.write_byte(BYTE_NULL)
end

private def encode_key(io, bool : Bool)
  io.write_byte(bool ? BYTE_TRUE : BYTE_FALSE)
end

private def encode_key(io, num : Int)
  encode_key(io, num.to_f64)
end

private def encode_key(io, num : Float64)
  # https://stackoverflow.com/questions/43299299/sorting-floating-point-values-using-their-byte-representation
  io.write_byte(num < 0 ? BYTE_DOUBLE_NEGATIVE : BYTE_DOUBLE_POSITIVE)
  bytes = Bytes.new(8)
  IO::ByteFormat::BigEndian.encode(num.abs, bytes)
  if num < 0
    bytes.map! { |byte| byte ^ 0xffu8 }
  else
    bytes[0] ^= 0x80u8
  end
  io.write(bytes)
end

private def encode_key(io, bytes : Bytes)
  io.write_byte(BYTE_BYTES)
  Base64.strict_encode(bytes, io)
  io.write_byte(BYTE_END)
end

private def encode_key(io, str : String)
  io.write_byte(BYTE_STRING)
  if str.byte_index(0)
    raise ReQL::QueryLogicError.new("Strings on keys can't have a null byte")
  end
  io << str
  io.write_byte(BYTE_END)
end

private def encode_key(io, arr : Array)
  io.write_byte(BYTE_ARRAY)
  arr.each do |e|
    encode_key(io, e)
  end
  io.write_byte(BYTE_END)
end

private def encode_key(io, hsh : Hash)
  io.write_byte(BYTE_OBJECT)
  hsh.each do |(k, v)|
    io << k
    io.write_byte(BYTE_END)
    encode_key(io, v)
  end
  io.write_byte(BYTE_END)
end
