require "./stream"
require "./row_value"
require "../../storage/*"
require "../jobs/table_scan_job"

module ReQL
  struct Table < Stream
    class InternalData
      property table_scan : ReQL::TableScanJob?
    end

    def reql_type
      "TABLE"
    end

    property name
    property db

    def initialize(@db : Db, @name : String, @manager : Storage::Manager)
      @internal = InternalData.new
    end

    def storage
      result = @manager.get_table(@db.name, @name)
      if result.nil?
        raise OpFailedError.new("Table `#{@db.name}.#{@name}` does not exist")
      end
      result
    end

    def get(key : Datum)
      RowReference.new(storage, key)
    end

    def start_reading
      @internal.table_scan = ReQL::TableScanJob.new(@manager.job_manager, storage)
    end

    def next_val
      val = @internal.table_scan.try &.receive

      case val
      when ReQL::TableScanJob::FinishedScan
        @internal.table_scan.try &.finish_job
        @internal.table_scan = nil
      when Exception
        @internal.table_scan.try &.finish_job
        @internal.table_scan = nil
        raise val
      else
        val
      end
    end

    def finish_reading
      @internal.table_scan.try &.finish_job
      @internal.table_scan = nil
    end

    def as_table
      self
    end
  end
end
