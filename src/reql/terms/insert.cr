require "uuid"
require "../term"
require "../../utils/waitgroup.cr"

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

      writter = TableWriter.new

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

      channel = Channel(Hash(String, Datum)).new(128)
      wait_group = WaitGroup.new
      jobs = 0
      consumers = 0

      docs.each do |obj|
        wait_group.add
        channel.send(obj)
        jobs += 1

        if Math.max(1, Math.log(jobs, 1.1).floor - 3) > consumers
          consumers += 1
          spawn start_inserter_worker(channel, wait_group, writter, table.storage)
        end
      end

      wait_group.wait
      channel.close

      @table_writers.last?.try &.merge(writter)

      writter.summary
    end
  end
end

private def start_inserter_worker(channel, wait_group, writter, storage)
  while obj = channel.receive?
    writter.insert(storage, obj)
    wait_group.done
  end
end
