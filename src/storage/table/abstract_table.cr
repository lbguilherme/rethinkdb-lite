module Storage
  abstract class AbstractTable
    def close
    end

    def get(key)
      result = nil
      scan do |obj|
        if obj.as(Hash)["id"] == key
          result = obj
        end
      end
      result
    end

    abstract def insert(obj : Hash(String, ReQL::Datum))
    abstract def replace(key : ReQL::Datum, &block : Hash(String, ReQL::Datum) -> Hash(String, ReQL::Datum))
    abstract def scan(&block : Hash(String, ReQL::Datum) ->)

    def count
      count = 0i64
      scan do
        count += 1i64
      end
      count
    end
  end
end
