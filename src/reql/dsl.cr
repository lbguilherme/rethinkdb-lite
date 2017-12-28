module ReQL
  module DSL
    module R
      @@next_var_i = 1i64
      alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | Int32 | String | Nil | R

      def self.reset_next_var_i
        @@next_var_i = 1i64
      end

      def self.convert_type(x : R, max_depth)
        x.val.as(Term::Type)
      end

      def self.convert_type(x : Term, max_depth)
        x.as(Term::Type)
      end

      def self.convert_type(block : R -> R::Type, max_depth)
        vari = {R.make_var_i}.map(&.as(Term::Type))
        vars = vari.map { |i| RExpr.new(VarTerm.new([i], nil), max_depth-1).as(R) }
        ReQL::FuncTerm.new([vari.to_a, R.convert_type(block.call(*vars), max_depth-1)].map(&.as(Term::Type)), nil).as(Term::Type)
      end

      def self.convert_type(x : Int32, max_depth)
        x.as(Term::Type)
      end

      def self.convert_type(x : Int, max_depth)
        x.to_i64.as(Term::Type)
      end

      def self.convert_type(x : Float, max_depth)
        x.to_f64.as(Term::Type)
      end

      def self.convert_type(x : Array, max_depth)
        if max_depth <= 0
          raise ReQL::DriverCompileError.new "Maximum expression depth exceeded (you can override this with `r.expr(X, MAX_DEPTH)`)"
        end

        x.map { |y| convert_type(y, max_depth-1).as(Term::Type) }.as(Term::Type)
      end

      def self.convert_type(x : Hash, max_depth)
        if max_depth <= 0
          raise ReQL::DriverCompileError.new "Maximum expression depth exceeded (you can override this with `r.expr(X, MAX_DEPTH)`)"
        end

        h = {} of String => Term::Type
        x.each do |(k, v)|
          unless k.is_a? String || k.is_a? Symbol
            raise ReQL::CompileError.new "Object keys must be strings or symbols."
          end
          h[k.to_s] = convert_type v, max_depth-1
        end
        h.as(Term::Type)
      end

      def self.convert_type(x : NamedTuple, max_depth)
        convert_type x.to_h, max_depth
      end

      def self.convert_type(x : Bool | Float64 | Int64 | String | Term | Nil, max_depth)
        x.as(Term::Type)
      end

      def self.make_var_i
        i = @@next_var_i
        @@next_var_i += 1
        i
      end

      def self.expr(*args)
        r(*args)
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

    def r(val, max_depth=20)
      unless max_depth.is_a? Int
        raise ReQL::CompileError.new "Second argument to `r.expr` must be a number."
      end

      RExpr.new(val, max_depth)
    end

    struct RExpr
      include R

      def initialize(val, max_depth)
        @val = R.convert_type(val, max_depth)
      end
    end

    macro term(name, term_class)
      struct R{{name}}
        include R

        def initialize(*args)
          @val = {{term_class}}.new(args.to_a.map { |x| R.convert_type(x, 20).as(Term::Type) }, nil)
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
    term eq, EqTerm
    term ne, NeTerm
  end
end
