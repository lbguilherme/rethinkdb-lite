module RethinkDB
  abstract class Connection
    abstract def authorize(user : String, password : String)
    abstract def use(db_name : String)
    abstract def start
    abstract def run(term : ReQL::Term::Type, runopts : RunOpts) : Datum | Cursor
    abstract def server : JSON::Any
    abstract def close
  end

  struct RunOpts
    getter native_binary : Bool

    def initialize(hash : Hash = {} of String => Nil)
      @native_binary = (hash["binaryFormat"]? || hash["binary_format"]?) != "raw"
    end

    def to_json(io)
      runopts = Hash(String, JSON::Any::Type).new
      if !@native_binary
        runopts["binary_format"] = "raw"
      end
      runopts.to_json(io)
    end
  end

  struct Datum
    getter value : Array(Datum) | Bool | Float64 | Hash(String, Datum) | Int64 | Int32 | Time | String | Nil | Bytes

    def initialize(value : ReQL::Datum | Datum | Array | Set | Bool | Float64 | Hash | Int64 | Int32 | Time | String | Nil | Bytes | ReQL::Maxval | ReQL::Minval, runopts : RunOpts)
      case value
      when ReQL::Datum
        initialize(value.value, runopts)
      when Datum
        @value = value.@value
      when Array, Set
        @value = value.map { |x| Datum.new(x.is_a?(JSON::Any) ? x.raw : x, runopts).as Datum }
      when Hash
        obj = {} of String => Datum
        value.each do |(k, v)|
          obj[k.to_s] = Datum.new(v.is_a?(JSON::Any) ? v.raw : v, runopts)
        end
        if runopts.native_binary && obj["$reql_type$"]? == "BINARY"
          @value = Base64.decode(obj["data"].string)
        else
          @value = obj
        end
      when ReQL::Maxval, ReQL::Minval
        raise "BUG: Maxval, Minval"
      when Bytes
        if runopts.native_binary
          @value = value
        else
          @value = Hash(String, Datum){
            "$reql_type$" => Datum.new("BINARY", runopts),
            "data"        => Datum.new(Base64.strict_encode(value), runopts),
          }
        end
      when Time
        if runopts.native_binary
          @value = value
        else
          @value = Hash(String, Datum){
            "$reql_type$" => Datum.new("TIME", runopts),
            "epoch_time"  => Datum.new(value.to_unix_f, runopts),
            "timezone"    => Datum.new(value.zone.format, runopts),
            "location"    => Datum.new(value.location.name, runopts),
          }
        end
      else
        @value = value
      end
    end

    def inspect(io)
      @value.inspect(io)
    end

    def to_json(io)
      case value = @value
      when Bytes
        Hash(String, Datum){
          "$reql_type$" => Datum.new("BINARY", RunOpts.new),
          "data"        => Datum.new(Base64.strict_encode(value), RunOpts.new),
        }.to_json(io)
      when Time
        Hash(String, Datum){
          "$reql_type$" => Datum.new("TIME", RunOpts.new),
          "epoch_time"  => Datum.new(value.to_unix_f, RunOpts.new),
          "timezone"    => Datum.new(value.zone.format, RunOpts.new),
          "location"    => Datum.new(value.location.name, RunOpts.new),
        }.to_json(io)
      else
        value.to_json(io)
      end
    end

    def datum
      self
    end

    def ==(other)
      @value == Datum.new(other, RunOpts.new).@value
    end

    def !=(other)
      @value != Datum.new(other, RunOpts.new).@value
    end

    def array
      @value.as Array(Datum)
    end

    def hash
      @value.as Hash(String, Datum)
    end

    def bool
      @value.as Bool
    end

    def string
      @value.as String
    end

    def bytes
      @value.as Bytes
    end

    def float
      @value.as(Float64 | Int64 | Int32).to_f64
    end

    def int32
      @value.as(Float64 | Int64 | Int32).to_i
    end

    def int64
      @value.as(Float64 | Int64 | Int32).to_i64
    end

    def array?
      @value.as? Array(Datum)
    end

    def hash?
      @value.as? Hash(String, Datum)
    end

    def bool?
      @value.as? Bool
    end

    def string?
      @value.as? String
    end

    def bytes?
      @value.as? Bytes
    end

    def float?
      @value.as?(Float64 | Int64 | Int32).try &.to_f64
    end

    def int32?
      @value.as?(Float64 | Int64 | Int32).try &.to_i
    end

    def int64?
      @value.as?(Float64 | Int64 | Int32).try &.to_i64
    end
  end

  abstract class Cursor
    include Iterator(Datum)

    def initialize
      @runopts = RunOpts.new
    end

    abstract def next

    def datum
      Datum.new to_a, @runopts
    end

    def close
    end
  end

  module DSL
    module R
      def self.connect(host : String)
        connect({"host" => host})
      end

      def self.connect(opts = {} of String => Nil)
        opts = {
          "host"     => "localhost",
          "port"     => 28015,
          "db"       => "test",
          "user"     => "admin",
          "password" => "",
        }.merge(opts.to_h)

        conn = RemoteConnection.new(opts["host"].as(String), opts["port"].as(Number).to_i)
        conn.authorize(opts["user"].as(String), opts["password"].as(String))
        conn.use(opts["db"].as(String))
        conn.start
        conn
      end

      def self.local_database(data_path)
        conn = LocalConnection.new(data_path)
        conn.start
        conn
      end
    end
  end
end
