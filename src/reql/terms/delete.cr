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
        channel = Channel({Storage::AbstractTable, Datum}).new(128)
        wait_group = WaitGroup.new
        jobs = 0
        consumers = 0

        source.each do |obj|
          row = obj.as_row
          wait_group.add
          channel.send({row.table, row.key})
          jobs += 1

          if Math.max(1, Math.log(jobs, 1.1).floor - 3) > consumers
            consumers += 1
            spawn start_deleter_worker(channel, wait_group, writter)
          end
        end

        wait_group.wait
        channel.close
      else
        row = source.as_row
        writter.delete(row.table, row.key)
      end

      @table_writers.last?.try &.merge(writter)

      writter.summary
    end
  end
end

private def start_deleter_worker(channel, wait_group, writter)
  while pair = channel.receive?
    writter.delete(pair[0], pair[1])
    wait_group.done
  end
end
