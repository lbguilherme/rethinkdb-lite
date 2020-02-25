require "../../src/driver/*"
require "spec"
require "file_utils"
include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  describe "set_difference" do
    it "returns an array without duplicates" do
      r([1, 1, 2]).set_difference([2, 3, 3]).run(conn).datum.array.map(&.int32).sort.should eq [1]
    end
  end
end

Spec.after_suite { conn.close }
