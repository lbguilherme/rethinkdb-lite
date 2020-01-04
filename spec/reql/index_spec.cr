require "../../src/driver/*"
require "spec"
require "file_utils"
include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  it "creates and lists created indexes" do
    r.table_create("test0").run(conn)
    r.table("test0").count.run(conn).should eq 0

    r.table("test0").index_status().count.run(conn).should eq 0
    r.table("test0").index_create("field2").run(conn)
    indexes = r.table("test0").index_status().run(conn).datum.array
    indexes.size.should eq 1
    indexes[0].hash["index"].should eq "field2"

    r.table("test0").index_list().run(conn).should eq ["field2"]
  end

end

Spec.after_suite { conn.close }
