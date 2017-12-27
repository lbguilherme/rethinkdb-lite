
module Storage
  abstract class AbstractTable
    def close
    end

    abstract def insert(obj : Hash)
    abstract def get(key : String)
    abstract def replace(key : String, &block : ReQL::Datum::Type -> ReQL::Datum::Type)
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
