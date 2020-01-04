require "uuid"

module ReQL
  class UpdateTerm < Term
    register_type UPDATE
    infix_inspect "update"

    def compile
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : UpdateTerm)
      source = eval(term.args[0])
      value = eval(term.args[1])

      writter = TableWriter.new

      if source.is_array?
        source.each do |obj|
          row = obj.as_row
          writter.atomic_update(row.table, row.key) do |old|
            if value.is_a?(Func)
              value.eval(self, {Datum.new(old)}).hash_value
            else
              value.hash_value
            end
          end
        end
      else
        row = source.as_row
        writter.atomic_update(row.table, row.key) do |old|
          if value.is_a?(Func)
            value.eval(self, {Datum.new(old)}).hash_value
          else
            value.hash_value
          end
        end
      end

      writter.summary
    end
  end
end
