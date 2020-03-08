require "./helpers/table_writer"
require "../utils/wait_group"
require "../storage/table/abstract_table"
require "./executor/datum"

class ReQL::Worker
  WORKER_COUNT = 128
  CHANNEL_SIZE = 10 * WORKER_COUNT

  @inserter = Channel({wait_group: WaitGroup, table_writer: TableWriter, table: Storage::AbstractTable, row: Hash(String, Datum)}).new(CHANNEL_SIZE)
  @deleter = Channel({wait_group: WaitGroup, table_writer: TableWriter, table: Storage::AbstractTable, key: Datum}).new(CHANNEL_SIZE)
  @closer = Channel(WaitGroup).new(WORKER_COUNT)

  def initialize
    WORKER_COUNT.times do
      spawn worker
    end
  end

  def close
    wait_group = WaitGroup.new
    WORKER_COUNT.times do
      wait_group.add
      @closer.send(wait_group)
    end
    wait_group.wait

    @inserter.close
    @closer.close
  end

  def insert(wait_group, table_writer, table, row)
    @inserter.send({wait_group: wait_group, table_writer: table_writer, table: table, row: row})
  end

  def delete(wait_group, table_writer, table, key)
    @deleter.send({wait_group: wait_group, table_writer: table_writer, table: table, key: key})
  end

  private def worker
    loop do
      select
      when wait_group = @closer.receive
        wait_group.done
        return
      when tuple = @inserter.receive
        tuple[:table_writer].insert(tuple[:table], tuple[:row])
        tuple[:wait_group].done
      when tuple = @deleter.receive
        tuple[:table_writer].delete(tuple[:table], tuple[:key])
        tuple[:wait_group].done
      end
    end
  rescue error
    STDERR.puts error.inspect_with_backtrace
    worker
  end
end
