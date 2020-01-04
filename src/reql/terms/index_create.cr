require "uuid"

module ReQL
  class IndexCreateTerm < Term
    register_type INDEX_CREATE
    infix_inspect "index_create"

    def compile
      expect_args 2, 3
    end
  end

  class Evaluator
    def eval(term : IndexCreateTerm)
      table = eval(term.args[0]).as_table
      storage = table.storage

      name = eval(term.args[1]).string_value

      function = if term.args.size == 3
                   eval(term.args[2]).as_function
                 else
                   FieldFunc.new(name)
                 end

      unless storage.is_a? Storage::PhysicalTable
        raise QueryLogicError.new("Database `rethinkdb` is special; you can't create secondary indexes on the tables in it")
      end

      writter = TableWriter.new
      writter.create_index(storage, name, function)

      @table_writers.last?.try &.merge(writter)

      writter.summary
    end
  end
end
