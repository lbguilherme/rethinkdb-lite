require "../../src/driver/*"
require "spec"
require "file_utils"
include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  describe "sample" do
    it "takes random elements from an array" do
      table = {1 => 0, 2 => 0, 3 => 0, 4 => 0}
      100.times do
        table[r([1, 2, 3, 4]).sample(1).run(conn).datum.array[0].int32] += 1
      end
      table[1].should be > 0
      table[2].should be > 0
      table[3].should be > 0
      table[4].should be > 0
    end

    it "takes random elements from a stream" do
      table = {1 => 0, 2 => 0, 3 => 0, 4 => 0}
      100.times do
        table[r.range(1, 5).sample(1).run(conn).datum.array[0].int32] += 1
      end
      table[1].should be > 0
      table[2].should be > 0
      table[3].should be > 0
      table[4].should be > 0
    end

    it "returns all elements if list is too short" do
      r.range(1, 5).sample(10).run(conn).datum.array.map(&.int32).sort.should eq [1, 2, 3, 4]
    end
  end
end

Spec.after_suite { conn.close }
