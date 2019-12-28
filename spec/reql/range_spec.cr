require "../../src/driver/*"
require "spec"
require "file_utils"
include RethinkDB::DSL

path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
FileUtils.rm_rf path
conn = r.local_database(path)

describe RethinkDB do
  it "finite ranges iterates from begin to end" do
    r.range(5, 176).run(conn).datum.should eq (5...176).to_a
    r.range(51, 58).run(conn).datum.should eq (51...58).to_a
    r.range(10, 10).run(conn).datum.should eq [] of Int64
    r.range(10, 2).run(conn).datum.should eq [] of Int64

    r.range(17).run(conn).datum.should eq (0...17).to_a
    r.range(0).run(conn).datum.should eq [] of Int64

    r.range.limit(4).run(conn).datum.should eq [0, 1, 2, 3]
    r.range(4).run(conn).datum.should eq [0, 1, 2, 3]
    r.range(4.0).run(conn).datum.should eq [0, 1, 2, 3]
    r.range(2, 5).run(conn).datum.should eq [2, 3, 4]
    r.range(0).run(conn).datum.should eq [] of Int64
    r.range(5, 2).run(conn).datum.should eq [] of Int64
    r.range(-5, -2).run(conn).datum.should eq [-5, -4, -3]
    r.range(-5, 2).run(conn).datum.should eq [-5, -4, -3, -2, -1, 0, 1]
  end

  it "raises on invalid range arguments" do
    expect_raises(ReQL::CompileError, "Expected between 0 and 2 arguments but found 3") do
      r.range(2, 5, 8).run(conn)
    end

    expect_raises(ReQL::QueryLogicError, "Expected type NUMBER but found STRING") do
      r.range("foo").run(conn)
    end

    expect_raises(ReQL::QueryLogicError, "Number not an integer (>2^53): 9007199254740994") do
      r.range(9007199254740994.0).run(conn)
    end

    expect_raises(ReQL::QueryLogicError, "Number not an integer (<-2^53): -9007199254740994") do
      r.range(-9007199254740994.0).run(conn)
    end

    expect_raises(ReQL::QueryLogicError, "Number not an integer: 0.5") do
      r.range(0.5).run(conn)
    end
  end

  it "finite ranges has consistent count" do
    r.range(5, 176).count.run(conn).should eq (5...176).size
    r.range(51, 58).count.run(conn).should eq (51...58).size
    r.range(10, 10).count.run(conn).should eq 0
    r.range(10, 2).count.run(conn).should eq 0

    r.range(17).count.run(conn).should eq (0...17).size
    r.range(0).count.run(conn).should eq 0
    r.range(4).count.run(conn).should eq 4
  end

  it "infinite ranges iterates from zero to infinity" do
    stream = r.range.run(conn).as RethinkDB::Cursor
    1000.times do |i|
      stream.next.should eq(i.to_i64)
    end
  end
end

Spec.after_suite { conn.close }
