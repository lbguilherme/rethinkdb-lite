require "../../src/reql/executor/datum.cr"
require "../../src/driver/*"
require "../../src/reql/encoder.cr"
require "spec"
include RethinkDB::DSL

describe ReQL::Datum do
  arr = [
    ReQL::Minval.new,
    [] of String,
    ["a"],
    ["a", "a"],
    ["aa", "a"],
    ["ab", "a"],
    ["b", "a"],
    ["c"],
    false,
    true,
    nil,
    -100000000001,
    -100000000000.5,
    -100000000000.0,
    -2,
    -1.6,
    -1.5,
    -1,
    0,
    1,
    1.5,
    1.6,
    2,
    100000000000.0,
    100000000000.5,
    100000000001,
    {} of String => String,
    {"a" => "b"},
    Bytes.new(0),
    Bytes[1, 1, 1],
    Bytes[1, 2],
    Bytes[1, 2, 3],
    "",
    "a",
    "aa",
    "aaa",
    "ab",
    ReQL::Maxval.new,
  ].map { |x| ReQL::Datum.new(x) }

  it "sorts in the correct order" do
    arr.each_with_index do |a, i|
      arr.each_with_index do |b, j|
        if i < j
          a.should be < b
        elsif i == j
          a.should eq b
        else
          a.should be > b
        end
      end
    end
  end

  it "sorts in the correct order after encoding to bytes" do
    arr.each_with_index do |_a, i|
      a = ReQL.encode_key(_a)
      ReQL.decode_key(a).should eq _a
      arr.each_with_index do |b, j|
        b = ReQL.encode_key(b)
        if i < j
          a.should be < b
        elsif i == j
          a.should eq b
        else
          a.should be > b
        end
      end
    end
  end

  _conn = r.connect("172.17.0.2") rescue r.connect("localhost") rescue r.connect("rethinkdb") rescue nil

  if _conn
    conn = _conn
    it "sorts in the same order on RethinkDB" do
      (1..(arr.size - 3)).each do |i|
        a = arr[i]
        b = arr[i + 1]

        aexpr = r.expr(JSON.parse(a.to_json))
        bexpr = r.expr(JSON.parse(b.to_json))

        unless aexpr.lt(bexpr).run(conn).datum.bool
          err = "'#{a.inspect}' should order before '#{b.inspect}'"
          fail err
        end
      end
    end

    Spec.after_suite do
      conn.close
    end
  else
    puts "Skipping tests with RethinkDB driver. Please run a RethinkDB instance at 172.17.0.2:28015 or localhost:28015 or rethinkdb:28015."
  end
end
