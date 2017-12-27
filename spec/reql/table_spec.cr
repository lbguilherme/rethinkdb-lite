require "spec"
require "../../src/reql/*"

include ReQL::DSL

describe ReQL do
  it "reading document that doesnt exist returns null" do
    r.table_create("test0").run
    r.table("test0").get(nil).run.value.should eq nil
    r.table("test0").get(123).run.value.should eq nil
    r.table("test0").get("123").run.value.should eq nil
    r.table("test0").get([1, 2, "aa"]).run.value.should eq nil
    r.table("test0").get(1.5).run.value.should eq nil
    r.table("test0").get({"x" => 5}).run.value.should eq nil
  end

  it "can insert and read from table" do
    r.table_create("test1").run
    r.table("test1").insert({"id" => 1, "value" => "hello"}).run.value.as(Hash)["inserted"].should eq 1
    r.table("test1").insert({"id" => 2, "value" => "bye"}).run.value.as(Hash)["inserted"].should eq 1

    r.table("test1").get(2).run.value.should eq({"id" => 2, "value" => "bye"})
    r.table("test1").get(1).run.value.should eq({"id" => 1, "value" => "hello"})
    r.table("test1").get(3).run.value.should eq nil
  end

  it "prevents insertion with duplicated keys" do
    r.table_create("test2").run
    r.table("test2").insert({"id" => 1, "value" => "hello"}).run.value.as(Hash)["inserted"].should eq 1
    r.table("test2").get(1).run.value.should eq({"id" => 1, "value" => "hello"})

    r.table("test2").insert({"id" => 1, "value" => "bye"}).run.value.as(Hash)["inserted"].should eq 0
    r.table("test2").get(1).run.value.should eq({"id" => 1, "value" => "hello"})
  end

  it "generates a key for you" do
    r.table_create("test3").run
    key1 = r.table("test3").insert({"value" => "hey"}).run.value.as(Hash)["generated_keys"].as(Array)[0].as(String)
    key2 = r.table("test3").insert({"value" => "hey"}).run.value.as(Hash)["generated_keys"].as(Array)[0].as(String)
    key1.should_not eq key2
    r.table("test3").get(key1).run.value.should eq({"id" => key1, "value" => "hey"})
    r.table("test3").get(key2).run.value.should eq({"id" => key2, "value" => "hey"})
  end

  it "presents all documents when doing a table scan" do
    r.table_create("test4").run
    r.table("test4").insert({"id" => 1, "value" => "hello"}).run
    r.table("test4").insert({"id" => 2, "value" => "bye"}).run
    r.table("test4").insert({"id" => 3, "value" => "lala"}).run

    list = r.table("test4").run.value.as(Array)
    list.map { |e| e.as(Hash)["value"].as(String) }.sort.should eq ["hello", "bye", "lala"].sort
  end

  it "counts the number of documents" do
    r.table_create("test5").run
    r.table("test5").count.run.value.should eq 0
    r.table("test5").insert({"a" => 1}).run
    r.table("test5").count.run.value.should eq 1
    r.table("test5").insert({"a" => 1}).run
    r.table("test5").count.run.value.should eq 2
    r.table("test5").insert({"a" => 1}).run
    r.table("test5").count.run.value.should eq 3
  end

  it "handles inserting and reading many rows" do
    r.table_create("test6").run
    1000.times do |i|
      r.table("test6").insert({"value" => i}).run
    end

    r.table("test6").run.value.as(Array).map { |x| x.as(Hash)["value"].as(Int64) }.sort.should eq (0...1000).to_a
  end

  it "accepts nil as a key" do
    r.table_create("test7").run
    r.table("test7").insert({"id" => nil, "value" => "well"}).run.value.as(Hash)["inserted"].should eq 1
    r.table("test7").get(nil).run.value.should eq({"id" => nil, "value" => "well"})
  end
end
