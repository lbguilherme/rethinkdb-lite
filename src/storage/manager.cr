require "./table/*"
require "./kv"

module Storage
  class Manager
    property databases = {} of String => Database

    record Database,
      info : KeyValueStore::DatabaseInfo,
      tables = Hash(String, KeyValueStore::TableInfo).new

    def initialize(path : String)
      @kv = KeyValueStore.new(path)

      db_by_id = {} of UUID => Database
      @kv.each_db do |info|
        db = Database.new(info)
        @databases[info.name] = db
        db_by_id[info.id] = db
      end

      @kv.each_table do |info|
        db_by_id[info.db].tables[info.name] = info
      end

      unless @databases.has_key?("test")
        create_db("test") { }
      end
    end

    def get_db(db_name)
      @databases[db_name]?.try &.info
    end

    def get_table(db_name, table_name) : AbstractTable?
      if db_name == "rethinkdb"
        case table_name
        when "db_config"
          return VirtualDbConfigTable.new(self)
        when "table_config"
          return VirtualTableConfigTable.new(self)
        else
          return nil
        end
      end

      info = @databases[db_name]?.try &.tables[table_name]?
      info.nil? ? nil : KvTable.new(@kv, info)
    end

    def create_db(db_name, id = nil)
      if db_name == "rethinkdb" || @databases.has_key?(db_name)
        raise ReQL::OpFailedError.new("Database `#{db_name}` already exists")
      end

      info = KeyValueStore::DatabaseInfo.new
      info.name = db_name
      if id
        info.id = id
        @kv.transaction do |t|
          old = t.get_db(info.id)

          unless old.nil?
            yield old, info
          end

          t.save_db(info)
        end
      else
        @kv.save_db(info)
      end
      @databases[info.name] = Database.new(info)
    end

    def create_table(db_name, table_name, primary_key, soft_durability)
      if db_name == "rethinkdb"
        raise ReQL::OpFailedError.new("Database `rethinkdb` is special; you can't create new tables in it")
      end

      db = @databases[db_name]?

      if db.nil?
        raise ReQL::OpFailedError.new("Database `#{db_name}` does not exist")
      end

      if db.tables.has_key?(table_name)
        raise ReQL::OpFailedError.new("Table `#{db_name}` already exists")
      end

      info = KeyValueStore::TableInfo.new
      info.db = db.info.id
      info.name = table_name
      info.primary_key = primary_key
      info.soft_durability = soft_durability
      @kv.save_table(info)
      db.tables[info.name] = info
    end

    def close
      @kv.close
    end

    def system_info
      @kv.system_info
    end
  end
end
