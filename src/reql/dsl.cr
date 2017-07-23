module ReQL
  module DSL
    module R
    end

    def r
      R
    end

    macro term(name, term_class)
      struct R{{name}}
        include R

        getter term : Term

        def initialize(*args)
          @term = {{term_class}}.new(args.to_a.map { |x| R{{name}}.convert_type(x).as(Term::Type) }, nil)
        end

        def self.convert_type(x : R)
          x.term.as(Term::Type)
        end

        def self.convert_type(x : Int)
          x.to_i64.as(Term::Type)
        end

        def self.convert_type(x : Float)
          x.to_f64.as(Term::Type)
        end

        def self.convert_type(x : Array)
          x.map { |y| self.convert_type y }.as(Term::Type)
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

        def run
          Term.eval @term
        end
      end

      module R
        def self.{{name}}(*args)
          R{{name}}.new(*args)
        end

        def {{name}}(*args)
          R{{name}}.new(self, *args)
        end
      end
    end

    term table, TableTerm
    term get, GetTerm
    term insert, InsertTerm
  end
end
