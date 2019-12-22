module ReQL
  class UuidTerm < Term
    register_type UUID
    prefix_inspect "uuid"

    UUID_NAMESPACE = UUID.new "91461c99-f89d-49d2-af96-d8e2e14e9b58"

    def compile
      expect_args(0, 1)
    end
  end

  class Evaluator
    def eval(term : UuidTerm)
      if term.args.size == 0
        Datum.new(UUID.random.to_s)
      else
        seed = eval(term.args[0]).string_value

        bytes = Bytes.new(16 + seed.bytesize)
        UuidTerm::UUID_NAMESPACE.bytes.to_slice.copy_to bytes.to_unsafe, 16
        seed.to_unsafe.copy_to bytes.to_unsafe + 16, seed.bytesize

        bytes = Digest::SHA1.digest(bytes).to_slice[0, 16]
        bytes[6] = ((bytes[6] & 0x0f) | 0x50)
        bytes[8] = ((bytes[8] & 0x3f) | 0x80)

        Datum.new(UUID.new(bytes).to_s)
      end
    end
  end
end
