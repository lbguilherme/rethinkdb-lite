require "spec"
require "../../src/driver/*"

include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  it "can take a slice of an array" do
    r([0, 1, 2, 3, 4]).slice(1, 3).run(conn).should eq [1, 2]
    r([0, 1, 2, 3, 4]).limit(3).run(conn).should eq [0, 1, 2]
    r([0, 1, 2, 3, 4]).limit(30).run(conn).should eq [0, 1, 2, 3, 4]
    r([0, 1, 2, 3, 4]).skip(3).run(conn).should eq [3, 4]
    r([0, 1, 2, 3, 4]).skip(30).run(conn).should eq [] of Int64
  end

  it "can count a slice of an array" do
    r([0, 1, 2, 3, 4]).slice(1, 3).count.run(conn).should eq 2
    r([0, 1, 2, 3, 4]).limit(3).count.run(conn).should eq 3
    r([0, 1, 2, 3, 4]).limit(30).count.run(conn).should eq 5
    r([0, 1, 2, 3, 4]).skip(3).count.run(conn).should eq 2
    r([0, 1, 2, 3, 4]).skip(30).count.run(conn).should eq 0
  end

  it "can take a slice of a stream" do
    r.range(5).slice(1, 3).run(conn).datum.should eq [1, 2]
    r.range(5).limit(3).run(conn).datum.should eq [0, 1, 2]
    r.range(5).limit(30).run(conn).datum.should eq [0, 1, 2, 3, 4]
    r.range(5).skip(3).run(conn).datum.should eq [3, 4]
    r.range(5).skip(30).run(conn).datum.should eq [] of Int64
  end

  it "can count a slice of a stream" do
    r.range(5).slice(1, 3).count.run(conn).should eq 2
    r.range(5).limit(3).count.run(conn).should eq 3
    r.range(5).limit(30).count.run(conn).should eq 5
    r.range(5).skip(3).count.run(conn).should eq 2
    r.range(5).skip(30).count.run(conn).should eq 0
  end

  it "can take a slice of an infinite stream" do
    r.range.skip(10).limit(2).run(conn).datum.should eq [10, 11]
  end
end

Spec.after_suite { conn.close }
