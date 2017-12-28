module ReQL
  module DSL
    module R
      @@next_var_i = 1i64
      alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | Int32 | String | Nil | R

      def self.reset_next_var_i
        @@next_var_i = 1i64
      end

      def self.convert_type(x : R)
        x.val.as(Term::Type)
      end

      def self.convert_type(x : Term)
        x.as(Term::Type)
      end

      def self.convert_type(block : R -> R::Type)
        vari = {R.make_var_i}.map(&.as(Term::Type))
        vars = vari.map { |i| RExpr.new(VarTerm.new([i], nil)).as(R) }
        ReQL::FuncTerm.new([vari.to_a, R.convert_type(block.call(*vars))].map(&.as(Term::Type)), nil).as(Term::Type)
      end

      def self.convert_type(x : Int32)
        x.as(Term::Type)
      end

      def self.convert_type(x : Int)
        x.to_i64.as(Term::Type)
      end

      def self.convert_type(x : Float)
        x.to_f64.as(Term::Type)
      end

      def self.convert_type(x : Array)
        x.map { |y| self.convert_type(y).as(Term::Type) }.as(Term::Type)
      end

      def self.convert_type(x : Hash)
        h = {} of String => Term::Type
        x.each do |(k, v)|
          h[k] = self.convert_type v
        end
        h.as(Term::Type)
      end

      def self.convert_type(x : Bool | Float64 | Int64 | String | Term | Nil)
        x.as(Term::Type)
      end

      def self.make_var_i
        i = @@next_var_i
        @@next_var_i += 1
        i
      end

      getter val : Term::Type

      def inspect(io)
        @val.inspect io
      end

      def run
        Evaluator.new.eval @val
      end
    end

    def r
      R
    end

    def r(val)
      RExpr.new(val)
    end

    struct RExpr
      include R

      def initialize(val)
        @val = R.convert_type(val)
      end
    end

    macro term(name, term_class)
      struct R{{name}}
        include R

        def initialize(*args)
          @val = {{term_class}}.new(args.to_a.map { |x| R.convert_type(x).as(Term::Type) }, nil)
        end
      end

      module R
        def self.{{name}}(*args)
          R{{name}}.new(*args)
        end

        def {{name}}(*args)
          R{{name}}.new(self, *args)
        end

        def self.{{name}}(*args, &block : R -> R::Type)
          R{{name}}.new(*args, block)
        end

        def {{name}}(*args, &block : R -> R::Type)
          R{{name}}.new(self, *args, block)
        end
      end
    end

    term db, DbTerm
    term db_create, DbCreateTerm
    term table, TableTerm
    term table_create, TableCreateTerm
    term get, GetTerm
    term insert, InsertTerm
    term count, CountTerm
    term range, RangeTerm
    term map, MapTerm
    term merge, MergeTerm
    term default, DefaultTerm
    term slice, SliceTerm
    term limit, LimitTerm
    term skip, SkipTerm
    term sum, SumTerm
    term order_by, OrderByTerm
    term eq, EqTerm
    term ne, NeTerm
  end
end
