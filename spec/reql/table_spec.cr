require "spec"
require "../../src/reql/*"

include ReQL::DSL

describe ReQL do
  it "reading document that doesnt exist returns null" do
    r.table("test0").get(123).run.value.should eq nil
    r.table("test0").get("123").run.value.should eq nil
    r.table("test0").get([1, 2, "aa"]).run.value.should eq nil
    r.table("test0").get(1.5).run.value.should eq nil
    r.table("test0").get({"x" => 5}).run.value.should eq nil
  end

  it "can insert and read from table" do
    r.table("test1").insert({"id" => 1, "value" => "hello"}).run.value.as(Hash)["inserted"].should eq 1
    r.table("test1").insert({"id" => 2, "value" => "bye"}).run.value.as(Hash)["inserted"].should eq 1

    r.table("test1").get(2).run.value.should eq({"id" => 2, "value" => "bye"})
    r.table("test1").get(1).run.value.should eq({"id" => 1, "value" => "hello"})
    r.table("test1").get(3).run.value.should eq nil
  end

  it "prevents insertion with duplicated keys" do
    r.table("test2").insert({"id" => 1, "value" => "hello"}).run.value.as(Hash)["inserted"].should eq 1
    r.table("test2").get(1).run.value.should eq({"id" => 1, "value" => "hello"})

    r.table("test2").insert({"id" => 1, "value" => "bye"}).run.value.as(Hash)["inserted"].should eq 0
    r.table("test2").get(1).run.value.should eq({"id" => 1, "value" => "hello"})
  end

  it "generates a key for you" do
    key = r.table("test3").insert({"value" => "hey"}).run.value.as(Hash)["generated_keys"].as(Array)[0].as(String)
    r.table("test3").get(key).run.value.should eq({"id" => key, "value" => "hey"})
  end

  it "presents all documents when doing a table scan" do
    r.table("test4").insert({"id" => 1, "value" => "hello"}).run
    r.table("test4").insert({"id" => 2, "value" => "bye"}).run
    r.table("test4").insert({"id" => 3, "value" => "lala"}).run

    list = r.table("test4").run.value.as(Array)
    list.map { |e| e.as(Hash)["value"].as(String) }.sort.should eq ["hello", "bye", "lala"].sort
  end

  it "counts the number of documents" do
    r.table("test5").count.run.value.should eq 0
    r.table("test5").insert({"a" => 1}).run
    r.table("test5").count.run.value.should eq 1
    r.table("test5").insert({"a" => 1}).run
    r.table("test5").count.run.value.should eq 2
    r.table("test5").insert({"a" => 1}).run
    r.table("test5").count.run.value.should eq 3
  end
end
