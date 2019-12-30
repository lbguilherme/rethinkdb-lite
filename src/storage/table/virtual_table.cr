module Storage
  abstract struct VirtualTable < AbstractTable
    def initialize(@name : String, @manager : Manager)
    end

    def replace(key, &block : Hash(String, ReQL::Datum)? -> Hash(String, ReQL::Datum)?)
      raise ReQL::QueryLogicError.new("It's illegal to write to the `rethinkdb.#{@name}` table.")
    end

    private def extract_error(message)
      raise ReQL::QueryLogicError.new("The change you're trying to make to `rethinkdb.#{@name}` has the wrong format. #{message}.")
    end

    private def extract_string(obj : Hash(String, ReQL::Datum), key : String, description : String)
      value = obj[key]?
      unless value
        extract_error "Expected a field named `#{key}`"
      end

      str = value.string_value?
      unless str
        extract_error "In `#{key}`: Expected #{description}; got #{str.inspect}"
      end

      str
    end

    private def extract_uuid(obj : Hash(String, ReQL::Datum), key : String)
      str = extract_string(obj, key, "a UUID")

      UUID.new(str) rescue extract_error "In `#{key}`: Expected a UUID; got #{str.inspect}"
    end

    private def check_extra_keys(obj : Hash(String, ReQL::Datum), keys)
      extra_keys = obj.keys - keys.to_a
      unless extra_keys.empty?
        extract_error "Unexpected key(s): #{extra_keys.join(", ")}"
      end
    end

    private def encode(info : Nil)
      nil
    end
  end
end
