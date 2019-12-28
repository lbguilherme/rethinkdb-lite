require "../../src/driver/*"
require "spec"
require "file_utils"
include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  it "reading document that doesnt exist returns null" do
    r.table_create("test0").run(conn)
    r.table("test0").get(nil).run(conn).should eq nil
    r.table("test0").get(123).run(conn).should eq nil
    r.table("test0").get("123").run(conn).should eq nil
    r.table("test0").get([1, 2, "aa"]).run(conn).should eq nil
    r.table("test0").get(1.5).run(conn).should eq nil
    r.table("test0").get({"x" => 5}).run(conn).should eq nil
  end

  it "can insert and read from table" do
    r.table_create("test1").run(conn)
    r.table("test1").insert({"id" => 1, "value" => "hello"}).run(conn).datum.hash["inserted"].should eq 1
    r.table("test1").insert({"id" => 2, "value" => "bye"}).run(conn).datum.hash["inserted"].should eq 1

    r.table("test1").count.run(conn).should eq 2
    r.table("test1").get(2).run(conn).should eq({"id" => 2, "value" => "bye"})
    r.table("test1").get(1).run(conn).should eq({"id" => 1, "value" => "hello"})
    r.table("test1").get(3).run(conn).should eq nil
  end

  it "prevents insertion with duplicated keys" do
    r.table_create("test2").run(conn)
    r.table("test2").insert({"id" => 1, "value" => "hello"}).run(conn).datum.hash["inserted"].should eq 1
    r.table("test2").get(1).run(conn).should eq({"id" => 1, "value" => "hello"})

    r.table("test2").insert({"id" => 1, "value" => "bye"}).run(conn).datum.hash["inserted"].should eq 0
    r.table("test2").get(1).run(conn).should eq({"id" => 1, "value" => "hello"})
  end

  it "generates a key for you" do
    r.table_create("test3").run(conn)
    key1 = r.table("test3").insert({"value" => "hey"}).run(conn).datum.hash["generated_keys"].array[0].string
    key2 = r.table("test3").insert({"value" => "hey"}).run(conn).datum.hash["generated_keys"].array[0].string
    key1.should_not eq key2
    r.table("test3").get(key1).run(conn).should eq({"id" => key1, "value" => "hey"})
    r.table("test3").get(key2).run(conn).should eq({"id" => key2, "value" => "hey"})
  end

  it "presents all documents when doing a table scan" do
    r.table_create("test4").run(conn)
    r.table("test4").insert({"id" => 1, "value" => "hello"}).run(conn)
    r.table("test4").insert({"id" => 2, "value" => "bye"}).run(conn)
    r.table("test4").insert({"id" => 3, "value" => "lala"}).run(conn)

    list = r.table("test4").run(conn).datum.array
    list.map { |e| e.hash["value"].string }.sort.should eq ["hello", "bye", "lala"].sort
  end

  it "counts the number of documents" do
    r.table_create("test5").run(conn)
    r.table("test5").count.run(conn).should eq 0
    r.table("test5").insert({"a" => 1}).run(conn)
    r.table("test5").count.run(conn).should eq 1
    r.table("test5").insert({"a" => 1}).run(conn)
    r.table("test5").count.run(conn).should eq 2
    r.table("test5").insert({"a" => 1}).run(conn)
    r.table("test5").count.run(conn).should eq 3
  end

  it "handles inserting and reading many rows" do
    r.table_create("test6").run(conn)
    400.times do |i|
      r.table("test6").insert({"value" => i}).run(conn)
    end

    r.table("test6").run(conn).datum.array.map { |x| x.hash["value"].int64 }.sort.should eq (0...400).to_a
  end

  it "accepts nil as a key" do
    r.table_create("test7").run(conn)
    r.table("test7").insert({"id" => nil, "value" => "well"}).run(conn).datum.hash["inserted"].should eq 1
    r.table("test7").get(nil).run(conn).should eq({"id" => nil, "value" => "well"})
  end

  it "inserts and queries by unicode" do
    r.table_create("test8").run(conn)
    r.table("test8").insert({"id" => "Здравствуй", "value" => "Земля!"}).run(conn).datum.hash["inserted"].should eq 1
    r.table("test8").get("Здравствуй").run(conn).should eq({"id" => "Здравствуй", "value" => "Земля!"})
    r.table("test8").filter({"value" => "Земля!"}).run(conn).datum.should eq([{"id" => "Здравствуй", "value" => "Земля!"}])
  end

  it "validates invalid table and db names" do
    expect_raises(ReQL::QueryLogicError, "Database name `%` invalid (Use A-Z, a-z, 0-9, _ and - only).") do
      r.db("%").run(conn)
    end

    expect_raises(ReQL::QueryLogicError, "Table name `%` invalid (Use A-Z, a-z, 0-9, _ and - only).") do
      r.db("test").table("%").run(conn)
    end
  end
end

Spec.after_suite { conn.close }
