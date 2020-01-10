require "../term"

module ReQL
  class ForEachTerm < Term
    infix_inspect "for_each"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval(term : ForEachTerm)
      target = eval(term.args[0])
      func = eval(term.args[1]).as_function

      writter = TableWriter.new
      @table_writers << writter

      begin
        target.each do |e|
          func.eval(self, {e.as_datum})
        end
      ensure
        @table_writers.pop
      end

      @table_writers.last?.try &.merge(writter)

      writter.summary
    end
  end
end
