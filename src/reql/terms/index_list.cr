require "uuid"

module ReQL
  class IndexListTerm < Term
    register_type INDEX_LIST
    infix_inspect "index_list"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : IndexListTerm)
      table = eval(term.args[0]).as_table
      storage = table.storage

      if storage.is_a? Storage::PhysicalTable
        storage.get_index_list
      else
        Datum.new([] of Datum)
      end
    end
  end
end
