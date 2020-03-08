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

      perform_writes do |writer, worker|
        if source.is_array?
          wait_group = WaitGroup.new
          source.each do |obj|
            row = obj.as_row
            wait_group.add
            worker.delete(wait_group, writer, row.table, row.key)
          end
          wait_group.wait
        else
          row = source.as_row
          writer.delete(row.table, row.key)
        end
      end
    end
  end
end

private def start_deleter_worker(channel, wait_group, writer)
  while pair = channel.receive?
    writer.delete(pair[0], pair[1])
    wait_group.done
  end
end
