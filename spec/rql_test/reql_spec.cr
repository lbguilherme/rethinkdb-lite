require "spec/*"
require "file_utils"
require "../../src/driver/*"

include RethinkDB::DSL

def run_reql_spec(conn)
  describe RethinkDB do
    {{ run("./reql_spec_generator", "spec/rql_test/src/datum/array.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/datum/bool.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/datum/null.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/datum/number.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/datum/object.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/datum/string.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/datum/typeof.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/datum/uuid.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/add.yaml") }}
    # {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/aliases.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/div.yaml") }}
    # {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/floor_ceil_round.yaml") }}
    # {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/logic.yaml") }}
    # {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/math.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/mod.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/mul.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/math_logic/sub.yaml") }}
    # {{ run("./reql_spec_generator", "spec/rql_test/src/aggregation.yaml") }}
    # {{ run("./reql_spec_generator", "spec/rql_test/src/control.yaml") }}
    # {{ run("./reql_spec_generator", "spec/rql_test/src/default.yaml") }}
    {{ run("./reql_spec_generator", "spec/rql_test/src/range.yaml") }}
  end
end

FileUtils.rm_rf "/tmp/rethinkdb-lite/spec-temp-tables"
conn = r.local_database("/tmp/rethinkdb-lite/spec-temp-tables")
run_reql_spec(conn)
conn.close

conn = begin
  r.connect("127.0.0.1")
rescue
  begin
    r.connect("172.17.0.2")
  rescue
    puts "Skipping tests with RethinkDB driver. Please run a RethinkDB instance at 127.0.0.1 or 172.17.0.2."
    nil
  end
end

if conn
  run_reql_spec(conn)
  conn.close
end

def match_reql_output(result)
  matcher = with ReqlMatchers.new yield
  recursive_match result, matcher
end

def recursive_match(result, target)
  case target
  when Matcher
    target.match(result)
  when Array
    result.array?.should be_a Array(RethinkDB::Datum)
    result.array.size.should eq target.size
    result.array.size.times do |i|
      recursive_match result.array[i], target[i]
    end
  when Hash
    result.hash?.should be_a Hash(String, RethinkDB::Datum)
    (result.hash.keys - target.keys).size.should eq 0
    result.hash.keys.each do |key|
      recursive_match result.hash[key], target[key]
    end
  else
    result.should eq target
  end
end

# def recursive_match(result : Array, target : Array)
#   result.should be_a Array(ReQL::Datum::Type)
#   result.size.should eq target.size
#   result.size.times do |i|
#     recursive_match result[i], target[i]
#   end
# end

struct ReqlMatchers
  def int_cmp(value)
    IntCmpMatcher.new(value.to_i64)
  end

  def float_cmp(value)
    FloatCmpMatcher.new(value.to_f64)
  end

  def uuid
    UUIDMatcher.new
  end

  def arrlen(len, matcher)
    ArrayMatcher.new(len, matcher)
  end

  def partial(matcher)
    PartialMatcher.new(matcher)
  end
end

abstract struct Matcher
end

struct IntCmpMatcher < Matcher
  def initialize(@value : Int64)
  end

  def match(result)
    result.int64.should eq @value
  end
end

struct FloatCmpMatcher < Matcher
  def initialize(@value : Float64)
  end

  def match(result)
    result.float.should eq @value
  end
end

struct UUIDMatcher < Matcher
  def match(result)
    result.string.should Spec::MatchExpectation.new(/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i)
  end
end

struct ArrayMatcher(T) < Matcher
  def initialize(@size : Int32, @matcher : T)
  end

  def match(result)
    result.array.size.should eq @size
    result.array.each do |value|
      recursive_match value, @matcher
    end
  end
end

struct PartialMatcher(T) < Matcher
  def initialize(@object : Hash(String, T))
  end

  def match(result)
    @object.keys.each do |key|
      result.hash.keys.includes?(key).should be_true
      recursive_match result.hash[key], @object[key]
    end
  end
end
