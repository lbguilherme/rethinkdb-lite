module Storage
  abstract struct AbstractTable
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

    abstract def replace(key : ReQL::Datum, durability : ReQL::Durability? = nil, &block : Hash(String, ReQL::Datum)? -> Hash(String, ReQL::Datum)?)
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

    abstract def index_scan(index_name : String, index_value_start : ReQL::Datum, index_value_end : ReQL::Datum, &block : Hash(String, ReQL::Datum) ->)
  end
end
