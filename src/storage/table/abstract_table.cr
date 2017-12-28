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

    abstract def insert(obj : Hash)
    abstract def get(key)
    abstract def replace(key, &block : ReQL::Datum::Type -> ReQL::Datum::Type)
    abstract def scan(&block : ReQL::Datum::Type ->)

    def count
      count = 0i64
      scan do
        count += 1i64
      end
      count
    end
  end
end
