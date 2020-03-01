require "uuid"
require "../term"

module ReQL
  class IndexStatusTerm < Term
    infix_inspect "index_status"

    def check
      expect_args 1, 2
    end
  end

  class Evaluator
    def eval_term(term : IndexStatusTerm)
      table = eval(term.args[0]).as_table
      storage = table.storage

      if term.args.size == 1
        if storage.is_a? Storage::PhysicalTable
          storage.get_all_indices_status
        else
          Datum.new([] of Datum)
        end
      else
        Datum.new(eval(term.args[1]).array_or_set_value.map do |name|
          name = name.string_value
          result = if storage.is_a? Storage::PhysicalTable
                     storage.get_index_status(name)
                   else
                     nil
                   end

          if result.nil?
            raise QueryLogicError.new("Index `#{name}` was not found on table `#{table.db.name}.#{table.name}`")
          end

          result
        end)
      end
    end
  end
end
