# require "./driver/*"
# require "./storage/kv"
# require "./storage/manager"
# require "./rocksdb"
# include RethinkDB::DSL
require "uuid"

# conn = r.local_database("/home/guilherme/rethinkdb-lite/test-rocksdb")
# p r.table("aaa").insert({"a" => rand}).run(conn).datum
# p r.table("aaa").run(conn).datum

p UUID.new("aa")

# options = RocksDb::Options.new
# options.create_if_missing = true
# options.paranoid_checks = true
# p options

# db = RocksDb::Database.open(options, "/home/guilherme/rethinkdb-lite/test-rocksdb")
# p db

# p db.get("\0".to_slice, RocksDb::ReadOptions.new)
# p db.put("\0".to_slice, "\0".to_slice, RocksDb::WriteOptions.new)
# p db.get("\0".to_slice, RocksDb::ReadOptions.new)
# p db.get("bbb".to_slice, RocksDb::ReadOptions.new)
