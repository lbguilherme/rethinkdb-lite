require "uuid"
require "../term"

module ReQL
  class DeleteTerm < Term
    infix_inspect "delete"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : DeleteTerm)
      source = eval(term.args[0])

      writter = TableWriter.new

      if source.is_array?
        source.each do |obj|
          row = obj.as_row
          writter.delete(row.table, row.key)
        end
      else
        row = source.as_row
        writter.delete(row.table, row.key)
      end

      @table_writers.last?.try &.merge(writter)

      writter.summary
    end
  end
end
