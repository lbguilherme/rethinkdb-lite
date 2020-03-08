require "uuid"
require "../term"
require "../../utils/wait_group.cr"

module ReQL
  class InsertTerm < Term
    infix_inspect "insert"

    def check
      expect_args 2
    end
  end

  class Evaluator
    def eval_term(term : InsertTerm)
      table = eval(term.args[0]).as_table
      datum = eval(term.args[1])

      docs = case
             when array = datum.array_or_set_value?
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

      perform_writes do |writer, worker|
        wait_group = WaitGroup.new
        docs.each do |obj|
          wait_group.add
          @worker.not_nil!.insert(wait_group, writer, table.storage, obj)
        end
        wait_group.wait
      end
    end
  end
end
