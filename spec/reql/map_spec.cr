require "../../src/driver/*"
require "spec"
require "file_utils"
include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  it "maps datum array to datum array" do
    r([1, 2, 3]).map { |x| x }.run(conn).should eq (1..3).to_a
    r([1, 2, 3]).map { |x| {"value" => x.as(R::Type)}.as(R::Type) }.run(conn).should eq (1..3).map { |x| {"value" => x} }
    r([1, 2, 3]).map { |x| x }.count.run(conn).should eq 3
  end

  it "maps stream to stream" do
    r.range(1, 4).map { |x| x }.run(conn).datum.should eq (1..3).to_a
    r.range(1, 4).map { |x| {"value" => x.as(R::Type)}.as(R::Type) }.run(conn).datum.should eq (1..3).map { |x| {"value" => x} }
    r.range(1, 4).map { |x| x }.count.run(conn).datum.should eq 3
  end

  it "maps into a stream (which is coerced into array)" do
    r.range(1, 10).map { |x| r.range(0, x) }.run(conn).datum.should eq (1...10).map { |i| (0...i).to_a }
  end

  it "counts across map" do
    r.range(10000).map { |x| x }.count.run(conn).should eq 10000
  end

  it "can map an infinite stream" do
    stream = r.range.map { |x| [x.as(R::Type)].as(R::Type) }.run(conn).as RethinkDB::Cursor
    1000.times do |i|
      stream.next.should eq([i.to_i64])
    end
    stream.close
  end

  it "accepts a string as a function" do
    r([{"a" => 3}, {"a" => 7}]).map("a").run(conn).datum.should eq [3, 7]
  end
end

Spec.after_suite { conn.close }
