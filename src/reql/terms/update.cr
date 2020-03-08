require "uuid"
require "../term"

module ReQL
  class UpdateTerm < Term
    infix_inspect "update"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : UpdateTerm)
      source = eval(term.args[0])
      value = eval(term.args[1])

      perform_writes do |writer|
        if source.is_array?
          source.each do |obj|
            row = obj.as_row
            writer.atomic_update(row.table, row.key) do |old|
              if value.is_a?(Func)
                value.eval(self, {Datum.new(old)}).hash_value
              else
                value.hash_value
              end
            end
          end
        else
          row = source.as_row
          writer.atomic_update(row.table, row.key) do |old|
            if value.is_a?(Func)
              value.eval(self, {Datum.new(old)}).hash_value
            else
              value.hash_value
            end
          end
        end
      end
    end
  end
end
