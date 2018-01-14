require "../reql/term"
require "../reql/terms/*"

macro if_defined(x)
  {% if x.resolve? %}
    {{yield}}
  {% end %}
end

module RethinkDB
  module DSL
    module R
      @@next_var_i = 1i64
      alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | Int32 | String | Nil | R

      def self.reset_next_var_i
        @@next_var_i = 1i64
      end

      def self.convert_type(x : R, max_depth)
        x.val.as(ReQL::Term::Type)
      end

      def self.convert_type(x : ReQL::Term, max_depth)
        x.as(ReQL::Term::Type)
      end

      def self.convert_type(block : R -> R::Type, max_depth)
        vari = {R.make_var_i}.map(&.as(ReQL::Term::Type))
        vars = vari.map { |i| RExpr.new(ReQL::VarTerm.new([i], nil), max_depth - 1).as(R) }
        ReQL::FuncTerm.new([vari.to_a, R.convert_type(block.call(*vars), max_depth - 1)].map(&.as(ReQL::Term::Type)), nil).as(ReQL::Term::Type)
      end

      def self.convert_type(x : Int32, max_depth)
        x.as(ReQL::Term::Type)
      end

      def self.convert_type(x : Bytes, max_depth)
        x.as(ReQL::Term::Type)
      end

      def self.convert_type(x : Int, max_depth)
        x.to_i64.as(ReQL::Term::Type)
      end

      def self.convert_type(x : Float, max_depth)
        x.to_f64.as(ReQL::Term::Type)
      end

      def self.convert_type(x : Array, max_depth)
        if max_depth <= 0
          raise ReQL::DriverCompileError.new "Maximum expression depth exceeded (you can override this with `r.expr(X, MAX_DEPTH)`)"
        end

        x.map { |y| convert_type(y, max_depth - 1).as(ReQL::Term::Type) }.as(ReQL::Term::Type)
      end

      def self.convert_type(x : Hash, max_depth)
        if max_depth <= 0
          raise ReQL::DriverCompileError.new "Maximum expression depth exceeded (you can override this with `r.expr(X, MAX_DEPTH)`)"
        end

        h = {} of String => ReQL::Term::Type
        x.each do |(k, v)|
          unless k.is_a? String || k.is_a? Symbol
            raise ReQL::CompileError.new "Object keys must be strings or symbols."
          end
          h[k.to_s] = convert_type v, max_depth - 1
        end
        h.as(ReQL::Term::Type)
      end

      def self.convert_type(x : NamedTuple, max_depth)
        convert_type x.to_h, max_depth
      end

      def self.convert_type(x : Bool | Float64 | Int64 | String | ReQL::Term | Nil, max_depth)
        x.as(ReQL::Term::Type)
      end

      def self.make_var_i
        i = @@next_var_i
        @@next_var_i += 1
        i
      end

      def self.expr(*args)
        r(*args)
      end

      getter val : ReQL::Term::Type

      def inspect(io)
        @val.inspect io
      end

      def run(conn, runopts : Hash = {} of String => Nil)
        if_defined(Spec) do
          ReQL::Term.encode(ReQL::Term.parse(ReQL::Term.encode(@val))).should ::eq ReQL::Term.encode(@val)
        end

        conn.run(@val, RunOpts.new(runopts))
        # Evaluator.new.eval @val
      end

      def +(other)
        add(other)
      end

      def -(other)
        sub(other)
      end

      def *(other)
        mul(other)
      end

      def /(other)
        div(other)
      end

      def %(other)
        mod(other)
      end

      def ==(other)
        eq(other)
      end

      def !=(other)
        ne(other)
      end

      def [](arg)
        bracket(arg)
      end

      def >(arg)
        gt(arg)
      end

      def >=(arg)
        ge(arg)
      end

      def <(arg)
        lt(arg)
      end

      def <=(arg)
        le(arg)
      end
    end

    def r
      R
    end

    def r(val, max_depth : Int = 20)
      RExpr.new(val, max_depth)
    end

    struct RExpr
      include R

      def initialize(val, max_depth)
        @val = R.convert_type(val, max_depth)
      end
    end

    macro term(name, term_class)
      struct R{{name.id}}
        include R

        def initialize(*args)
          @val = ReQL::{{term_class}}.new(args.to_a.map { |x| R.convert_type(x, 20).as(ReQL::Term::Type) }, nil)
        end
      end

      module R
        def self.{{name.id}}(*args)
          R{{name.id}}.new(*args)
        end

        def {{name.id}}(*args)
          R{{name.id}}.new(self, *args)
        end

        def self.{{name.id}}(*args, &block : R -> R::Type)
          R{{name.id}}.new(*args, block)
        end

        def {{name.id}}(*args, &block : R -> R::Type)
          R{{name.id}}.new(self, *args, block)
        end
      end
    end

    term db, DbTerm
    term db_create, DbCreateTerm
    term table, TableTerm
    term table_create, TableCreateTerm
    term get, GetTerm
    term insert, InsertTerm
    term bracket, BracketTerm
    term "do", DoTerm
    term count, CountTerm
    term range, RangeTerm
    term uuid, UuidTerm
    term filter, FilterTerm
    term map, MapTerm
    term merge, MergeTerm
    term default, DefaultTerm
    term slice, SliceTerm
    term limit, LimitTerm
    term skip, SkipTerm
    term sum, SumTerm
    term object, ObjectTerm
    term type_of, TypeOfTerm
    term coerce_to, CoerceToTerm
    term order_by, OrderByTerm
    term distinct, DistinctTerm
    term split, SplitTerm
    term upcase, UpCaseTerm
    term downcase, DownCaseTerm
    term insert_at, InsertAtTerm
    term change_at, ChangeAtTerm
    term splice_at, SpliceAtTerm
    term delete_at, DeleteAtTerm
    term add, AddTerm
    term sub, SubTerm
    term mul, MulTerm
    term div, DivTerm
    term mod, ModTerm
    term eq, EqTerm
    term ne, NeTerm
    term gt, GtTerm
    term ge, GeTerm
    term lt, LtTerm
    term le, LeTerm
    term floor, FloorTerm
    term ceil, CeilTerm
    term round, RoundTerm
    term minval, MinvalTerm
    term maxval, MaxvalTerm
    term binary, BinaryTerm
  end
end

class Object
  def +(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).add(other)
  end

  def -(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).sub(other)
  end

  def *(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).mul(other)
  end

  def /(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).div(other)
  end

  def %(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).mod(other)
  end

  def ==(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).eq(other)
  end

  def !=(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).ne(other)
  end

  def >(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).gt(other)
  end

  def >=(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).ge(other)
  end

  def <(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).lt(other)
  end

  def <=(other : RethinkDB::DSL::R)
    RethinkDB::DSL::RExpr.new(self, 1).le(other)
  end
end
