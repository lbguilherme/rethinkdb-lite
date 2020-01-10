require "digest/sha1"
require "../term"

module ReQL
  class UuidTerm < Term
    prefix_inspect "uuid"

    UUID_NAMESPACE = UUID.new("91461c99-f89d-49d2-af96-d8e2e14e9b58").bytes

    def check
      expect_args(0, 1)
    end
  end

  class Evaluator
    def eval(term : UuidTerm)
      if term.args.size == 0
        Datum.new(UUID.random.to_s)
      else
        seed = eval(term.args[0]).string_value

        bytes = Digest::SHA1.digest do |ctx|
          ctx.update UuidTerm::UUID_NAMESPACE
          ctx.update seed
        end

        bytes[6] = ((bytes[6] & 0x0f) | 0x50)
        bytes[8] = ((bytes[8] & 0x3f) | 0x80)

        Datum.new(UUID.new(bytes.to_slice[0, 16]).to_s)
      end
    end
  end
end
