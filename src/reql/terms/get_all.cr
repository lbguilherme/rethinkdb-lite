require "../term"

module ReQL
  class GetAllTerm < Term
    infix_inspect "get_all"

    def check
      expect_args_at_least 2
      expect_maybe_options "index"
    end
  end

  class Evaluator
    def eval_term(term : GetAllTerm)
      table = eval(term.args[0]).as_table
      keys = term.args[1..-1].map { |arg| eval(arg).as_datum }

      storage = table.storage

      index = term.options["index"]?.try { |x| Datum.new(x).string_value } || storage.primary_key

      GetAllStream.new(storage, keys, index)
    end
  end
end
