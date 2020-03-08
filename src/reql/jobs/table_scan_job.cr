require "./job"
require "../executor/row_value"

class ReQL::TableScanJob < ReQL::Job
  struct FinishedScan
  end

  @channel = Channel(RowValue | FinishedScan | Exception).new(64)
  getter table

  def initialize(job_manager, @table : Storage::AbstractTable)
    super(job_manager)
    spawn worker
  end

  def receive
    raise QueryLogicError.new "Table scan terminated." unless @running
    @channel.receive
  end

  private def worker
    @table.scan do |row|
      @channel.send RowValue.new(@table, row)
      unless @running
        return
      end
    end
    @channel.send FinishedScan.new
  rescue Channel::ClosedError
  rescue error
    @channel.send error
  end

  def type : String
    "table_scan"
  end
end
