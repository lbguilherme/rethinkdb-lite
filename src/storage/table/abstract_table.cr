module Storage
  abstract class AbstractTable
    def close
    end

    def get(key : ReQL::Datum::Type)
      result = nil
      scan do |obj|
        if obj.as(Hash)["id"] == key
          result = obj
        end
      end
      result
    end

    abstract def insert(obj : Hash(String, ReQL::Datum::Type))
    abstract def replace(key : ReQL::Datum::Type, &block : Hash(String, ReQL::Datum::Type) -> Hash(String, ReQL::Datum::Type))
    abstract def scan(&block : Hash(String, ReQL::Datum::Type) ->)

    def count
      count = 0i64
      scan do
        count += 1i64
      end
      count
    end
  end
end
