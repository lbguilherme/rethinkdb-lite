require "./abstract_table"

module Storage
  abstract struct VirtualTable < AbstractTable
    def initialize(@name : String, @manager : Manager)
    end

    def replace(key, durability : ReQL::Durability? = nil, &block : Hash(String, ReQL::Datum)? -> Hash(String, ReQL::Datum)?)
      raise ReQL::QueryLogicError.new("It's illegal to write to the `rethinkdb.#{@name}` table.")
    end

    def index_scan(index_name : String, index_value_start : ReQL::Datum, index_value_end : ReQL::Datum, &block : Hash(String, ReQL::Datum) ->)
      raise ReQL::QueryLogicError.new "Index `#{index_name}` was not found on table `rethinkdb.#{@name}`"
    end

    private def extract_error(message)
      raise ReQL::QueryLogicError.new("The change you're trying to make to `rethinkdb.#{@name}` has the wrong format. #{message}.")
    end

    private def extract_string(obj : Hash(String, ReQL::Datum), key : String, description : String = "a string")
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

    private def extract_table_name(obj : Hash(String, ReQL::Datum), key : String)
      name = extract_string(obj, key, "a table name")
      unless name =~ /\A[A-Za-z0-9_-]+\Z/
        raise ReQL::QueryLogicError.new "In `#{key}`: Table name `#{name}` invalid (Use A-Z, a-z, 0-9, _ and - only)."
      end
      name
    end

    private def extract_db_name(obj : Hash(String, ReQL::Datum), key : String)
      name = extract_string(obj, key, "a database name")
      unless name =~ /\A[A-Za-z0-9_-]+\Z/
        raise ReQL::QueryLogicError.new "In `#{key}`: Database name `#{name}` invalid (Use A-Z, a-z, 0-9, _ and - only)."
      end
      name
    end

    private def extract_db_reference(obj : Hash(String, ReQL::Datum), key : String)
      name = extract_db_name(obj, key)
      id = @manager.databases[name]?.try &.info.id
      if id.nil?
        extract_error "In `#{key}`: Database `#{name}` does not exist"
      end
      id
    end

    private def extract_durability(obj : Hash(String, ReQL::Datum), key : String)
      str = extract_string(obj, key)
      case str
      when "soft"
        ReQL::Durability::Soft
      when "hard"
        ReQL::Durability::Hard
      when "minimal"
        ReQL::Durability::Minimal
      else
        extract_error "In `#{key}`: Expected \"soft\", \"hard\" or \"minimal\", got: `#{str}`"
      end
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
