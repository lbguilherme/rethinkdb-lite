require "../../src/driver/*"
require "spec"
require "file_utils"
include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  describe "nth" do
    it "takes the nth element of an array" do
      r([1, 2, 3, 4]).nth(0).run(conn).should eq 1
      r([1, 2, 3, 4]).nth(1).run(conn).should eq 2
      r([1, 2, 3, 4]).nth(2).run(conn).should eq 3
      r([1, 2, 3, 4]).nth(3).run(conn).should eq 4
      expect_raises(ReQL::NonExistenceError, "Index out of bounds: 4") do
        r([1, 2, 3, 4]).nth(4).run(conn)
      end
    end

    it "takes the nth element of an array starting from the last element" do
      r([1, 2, 3, 4]).nth(-1).run(conn).should eq 4
      r([1, 2, 3, 4]).nth(-2).run(conn).should eq 3
      r([1, 2, 3, 4]).nth(-3).run(conn).should eq 2
      r([1, 2, 3, 4]).nth(-4).run(conn).should eq 1
      expect_raises(ReQL::NonExistenceError, "Index out of bounds: -5") do
        r([1, 2, 3, 4]).nth(-5).run(conn)
      end
    end

    it "takes the nth element of a stream" do
      r.range(1, 5).nth(0).run(conn).should eq 1
      r.range(1, 5).nth(1).run(conn).should eq 2
      r.range(1, 5).nth(2).run(conn).should eq 3
      r.range(1, 5).nth(3).run(conn).should eq 4
      expect_raises(ReQL::NonExistenceError, "Index out of bounds: 4") do
        r.range(1, 5).nth(4).run(conn)
      end
    end

    it "takes the nth element of a stream starting from the last element" do
      r.range(1, 5).nth(-1).run(conn).should eq 4
      r.range(1, 5).nth(-2).run(conn).should eq 3
      r.range(1, 5).nth(-3).run(conn).should eq 2
      r.range(1, 5).nth(-4).run(conn).should eq 1
      expect_raises(ReQL::NonExistenceError, "Index out of bounds: -5") do
        r.range(1, 5).nth(-5).run(conn)
      end
    end

    it "fails for other types that are neither array nor stream" do
      expect_raises(ReQL::QueryLogicError, "Cannot convert STRING to SEQUENCE") do
        r("hello").nth(0).run(conn)
      end
      expect_raises(ReQL::QueryLogicError, "Cannot convert NUMBER to SEQUENCE") do
        r(20).nth(0).run(conn)
      end
    end
  end
end

Spec.after_suite { conn.close }
