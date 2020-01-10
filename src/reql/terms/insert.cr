require "uuid"
require "../term"

module ReQL
  class InsertTerm < Term
    infix_inspect "insert"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : InsertTerm)
      table = eval(term.args[0]).as_table
      datum = eval(term.args[1])

      writter = TableWriter.new

      docs = case
             when array = datum.array_value?
               array.map do |e|
                 if hash = e.hash_value?
                   hash
                 else
                   raise QueryLogicError.new("Expected type OBJECT but found #{e.reql_type}")
                 end
               end
             when hash = datum.hash_value?
               [hash]
             else
               raise QueryLogicError.new("Expected type OBJECT but found #{datum.reql_type}")
             end

      docs.each do |obj|
        writter.insert(table.storage, obj)
      end

      @table_writers.last?.try &.merge(writter)

      writter.summary
    end
  end
end
