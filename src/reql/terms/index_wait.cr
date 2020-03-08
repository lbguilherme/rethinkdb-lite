require "uuid"
require "../term"

module ReQL
  class IndexWaitTerm < Term
    infix_inspect "index_wait"

    def check
      expect_args 1, 2
    end
  end

  class Evaluator
    def eval_term(term : IndexWaitTerm)
      table = eval(term.args[0]).as_table
      storage = table.storage
      indices = term.args[1..-1].map { |arg| eval(arg) } if term.args.size > 1

      while true
        list = if term.args.size == 1
                 if storage.is_a? Storage::PhysicalTable
                   storage.get_all_indices_status
                 else
                   Datum.new([] of Datum)
                 end
               else
                 Datum.new(indices.not_nil!.map do |name|
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

        return list if list.array_value.all? { |entry| entry.hash_value["ready"] == true }

        sleep 0.5
      end
    end
  end
end
