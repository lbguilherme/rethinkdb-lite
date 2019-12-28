module Storage
  abstract class AbstractTable
    def close
    end

    def get(key)
      result = nil
      scan do |row|
        if row["id"] == key
          result = row
        end
      end
      result
    end

    abstract def insert(obj : Hash(String, ReQL::Datum))
    abstract def delete(key : ReQL::Datum)
    abstract def replace(key : ReQL::Datum, &block : Hash(String, ReQL::Datum) -> Hash(String, ReQL::Datum))
    abstract def scan(&block : Hash(String, ReQL::Datum) ->)

    def primary_key
      "id"
    end

    def count
      count = 0i64
      scan do
        count += 1i64
      end
      count
    end

    def duplicated_primary_key_error(existing_value, new_value)
      pretty_existing = JSON.build(4) { |builder| existing_value.to_json(builder) }
      pretty_new = JSON.build(4) { |builder| new_value.to_json(builder) }
      raise ReQL::OpFailedError.new("Duplicate primary key `#{primary_key}`:\n#{pretty_existing}\n#{pretty_new}")
    end
  end
end
