module Storage
  abstract struct VirtualTable < AbstractTable
    def initialize(@name : String)
    end

    def replace(key, &block : Hash(String, ReQL::Datum)? -> Hash(String, ReQL::Datum)?)
      raise ReQL::QueryLogicError.new("It's illegal to write to the `rethinkdb.#{@name}` table.")
    end

    private def extract_string(obj : Hash(String, ReQL::Datum), key : String, description : String)
      value = obj[key]?
      unless value
        raise ReQL::QueryLogicError.new("The change you're trying to make to `rethinkdb.#{@name}` has the wrong format. Expected a field named `name`.")
      end

      str = value.string_value?
      unless str
        raise ReQL::QueryLogicError.new("The change you're trying to make to `rethinkdb.#{@name}` has the wrong format. In `#{key}`: Expected #{description}; got #{str.inspect}")
      end

      str
    end

    private def extract_uuid(obj : Hash(String, ReQL::Datum), key : String)
      str = extract_string(obj, key, "a UUID")

      UUID.new(str) rescue raise ReQL::QueryLogicError.new("The change you're trying to make to `rethinkdb.#{@name}` has the wrong format. In `#{key}`: Expected a UUID; got #{str.inspect}")
    end

    private def check_extra_keys(obj : Hash(String, ReQL::Datum), keys)
      extra_keys = obj.keys - keys.to_a
      unless extra_keys.empty?
        raise ReQL::QueryLogicError.new("The change you're trying to make to `rethinkdb.#{@name}` has the wrong format. Unexpected key(s): #{extra_keys.join(", ")}")
      end
    end

    private def encode(info : Nil)
      nil
    end
  end
end
