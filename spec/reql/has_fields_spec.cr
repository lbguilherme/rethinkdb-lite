require "../../src/driver/*"
require "spec"
require "file_utils"
include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  describe "has_fields" do
    it "checks if an object have the specified fields" do
      r({"a" => 1, "b" => 2}).has_fields("a").run(conn).should eq true
      r({"a" => 1, "b" => 2}).has_fields("b").run(conn).should eq true
      r({"a" => 1, "b" => 2}).has_fields("a", "b").run(conn).should eq true
      r({"a" => 1, "b" => 2}).has_fields("a", "c").run(conn).should eq false
      r({"a" => 1, "b" => 2}).has_fields("a", "b", "c").run(conn).should eq false
      r({"a" => 1, "b" => 2}).has_fields("c").run(conn).should eq false
    end

    it "checks if an inner object have the specified fields" do
      r({"a" => {"inner" => 10, "another" => 11}, "b" => 2}).has_fields("a").run(conn).should eq true
      r({"a" => {"inner" => 10, "another" => 11}, "b" => 2}).has_fields({"a" => "inner"}).run(conn).should eq true
      r({"a" => {"inner" => 10, "another" => 11}, "b" => 2}).has_fields({"b" => "inner"}).run(conn).should eq false
      r({"a" => {"inner" => 10, "another" => 11}, "b" => 2}).has_fields({"a" => "doesnt"}).run(conn).should eq false
      r({"a" => {"inner" => 10, "another" => 11}, "b" => 2}).has_fields({"a" => {"inner" => true}}).run(conn).should eq true
      r({"a" => {"inner" => 10, "another" => 11}, "b" => 2}).has_fields({"a" => {"inner" => true, "another" => true}}).run(conn).should eq true
      r({"a" => {"inner" => 10, "another" => 11}, "b" => 2}).has_fields({"a" => {"inner" => true, "another" => true}}, "b").run(conn).should eq true
      r({"a" => {"inner" => 10, "another" => 11}, "b" => 2}).has_fields({"a" => {"inner" => true, "another" => true}}, "c").run(conn).should eq false
    end

    it "filters if applied on an array" do
      r([{"a" => 1}, {"b" => 2}, {"a" => 3}]).has_fields("a").run(conn).should eq [{"a" => 1}, {"a" => 3}]
      r([{"a" => 1}, {"b" => 2}, {"a" => 3}]).has_fields("b").run(conn).should eq [{"b" => 2}]
    end
  end
end

Spec.after_suite { conn.close }
