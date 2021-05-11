require "spec"
require "file_utils"
require "../../src/driver/*"
require "../../src/server/*"

include RethinkDB::DSL

def run_reql_spec(conn)
  describe RethinkDB do
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/array.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/binary.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/bool.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/null.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/number.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/object.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/string.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/typeof.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/datum/uuid.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/add.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/aliases.yaml") }}
    # {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/bit.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/comparison.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/div.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/floor_ceil_round.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/logic.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/math.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/mod.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/mul.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/math_logic/sub.yaml") }}
    # {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/aggregation.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/control.yaml") }}
    # {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/default.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/range.yaml") }}
    {{ run("./reql_spec_generator", "spec/original_rethinkdb_testsuite/src/transform/table.yaml") }}
  end
end

test_local_database
test_remote_connection_over_local_database
test_remote_connection_over_rethinkdb

def test_local_database
  path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
  FileUtils.rm_rf path
  conn = r.local_database(path)
  run_reql_spec(conn)
  Spec.after_suite do
    conn.close
  end
end

def test_remote_connection_over_local_database
  path = "/tmp/rethinkdb-lite/spec-temp-tables/#{Random::Secure.hex}"
  FileUtils.rm_rf path
  real_conn = r.local_database(path)
  server = RethinkDB::Server::DriverServer.new(28099, real_conn)
  server.start
  conn = r.connect({"host" => "localhost", "port" => 28099})
  run_reql_spec(conn)
  Spec.after_suite do
    conn.close
    server.close
    real_conn.close
  end
end

def test_remote_connection_over_rethinkdb
  conn = begin
    r.connect("172.17.0.2") rescue r.connect("localhost") rescue r.connect("rethinkdb")
  rescue
    puts "Skipping tests with RethinkDB driver. Please run a RethinkDB instance at 172.17.0.2:28015 or localhost:28015 or rethinkdb:28015."
    return
  end

  run_reql_spec(conn)
  Spec.after_suite do
    conn.close
  end
end

def match_reql_output(result)
  matcher = with ReqlMatchers.new yield
  recursive_match result, matcher
end

def recursive_match(result, target)
  if result.bytes? && target.is_a? String
    target = target.to_slice
  end
  case target
  when Matcher
    target.match(result)
  when Array
    result.value.should be_a Array(RethinkDB::Datum)
    result.array.size.should eq target.size
    result.array.size.times do |i|
      recursive_match result.array[i], target[i]
    end
  when Hash
    result.value.should be_a Hash(String, RethinkDB::Datum)
    result.hash.keys.sort.should eq target.keys.sort
    result.hash.keys.each do |key|
      recursive_match result.hash[key], target[key]
    end
  else
    result.should eq target
  end
end

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
