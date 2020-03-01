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

    r.table("test0").index_status.count.run(conn).should eq 0
    r.table("test0").index_create("field2").run(conn)
    indexes = r.table("test0").index_status.run(conn).datum.array
    indexes.size.should eq 1
    indexes[0].hash["index"].should eq "field2"

    r.table("test0").index_list.run(conn).should eq ["field2"]
  end

  it "created index operates on new data with get_all" do
    r.table_create("test1").run(conn)
    r.table("test1").count.run(conn).should eq 0
    r.table("test1").index_status.count.run(conn).should eq 0

    r.table("test1").index_create("name").run(conn)
    r.table("test1").index_create("namelen") { |x| x["name"].count }.run(conn)
    r.table("test1").index_create("namelen_and_id", multi: true) { |x| [x["name"].count, x["id"]] }.run(conn)
    r.table("test1").insert({id: 1, name: "Hey"}).run(conn)
    r.table("test1").insert({id: 2, name: "haha"}).run(conn)
    r.table("test1").insert({id: 3, name: "Aho"}).run(conn)
    r.table("test1").insert({id: 4, name: "Aho"}).run(conn)

    r.table("test1").count.run(conn).should eq 4
    r.table("test1").get_all("Hey", index: "name").run(conn).datum.should eq [{"id" => 1, "name" => "Hey"}]

    result = r.table("test1").get_all("Aho", index: "name").run(conn).datum.array
    result.size.should eq 2
    result.should contain ({"id" => 3, "name" => "Aho"})
    result.should contain ({"id" => 4, "name" => "Aho"})

    result = r.table("test1").get_all(3, index: "namelen").run(conn).datum.array
    result.size.should eq 3
    result.should contain ({"id" => 1, "name" => "Hey"})
    result.should contain ({"id" => 3, "name" => "Aho"})
    result.should contain ({"id" => 4, "name" => "Aho"})

    result = r.table("test1").get_all(3, 4, index: "namelen").run(conn).datum.array
    result.size.should eq 4
    result.should contain ({"id" => 1, "name" => "Hey"})
    result.should contain ({"id" => 2, "name" => "haha"})
    result.should contain ({"id" => 3, "name" => "Aho"})
    result.should contain ({"id" => 4, "name" => "Aho"})

    result = r.table("test1").get_all(3, index: "namelen_and_id").run(conn).datum.array
    result.size.should eq 4
    result.should contain ({"id" => 1, "name" => "Hey"})
    result.should contain ({"id" => 3, "name" => "Aho"})
    result.should contain ({"id" => 4, "name" => "Aho"})
    result.select { |x| x == {"id" => 3, "name" => "Aho"} }.size.should eq 2

    r.table("test1").get_all(2, index: "namelen_and_id").run(conn).datum.should eq [{"id" => 2, "name" => "haha"}]
  end

  it "can create index on existing data" do
    r.table_create("test2").run(conn)
    r.table("test2").count.run(conn).should eq 0
    r.table("test2").index_status.count.run(conn).should eq 0

    r.table("test2").insert({id: 1, name: "Hey"}).run(conn)
    r.table("test2").insert({id: 2, name: "Hi"}).run(conn)
    r.table("test2").index_create("name").run(conn)

    r.table("test2").index_status("name").run(conn).datum.hash["ready"].should be_false
    until r.table("test2").index_status("name").run(conn).datum.hash["ready"] == true
      sleep 0.1
    end
    r.table("test2").index_status("name").run(conn).datum.hash["ready"].should be_true

    r.table("test2").get_all("Hi", index: "name").run(conn).datum.should eq [{"id" => 2, "name" => "Hi"}]
  end
end

Spec.after_suite { conn.close }
