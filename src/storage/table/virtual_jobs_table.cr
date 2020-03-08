require "./virtual_table"
require "../../reql/jobs/*"

module Storage
  struct VirtualJobsTable < VirtualTable
    def initialize(manager : Manager)
      super("jobs", manager)
    end

    def get(key)
      arr = key.array_value rescue return nil
      return nil if arr.size != 2
      type = arr[0].string_value rescue return nil
      id = UUID.new(arr[1].string_value) rescue return nil
      job = @manager.job_manager.lock.synchronize { @manager.job_manager.jobs[id]? }
      return nil unless job
      return nil unless job.type == type
      encode(job)
    end

    private def encode(job : ReQL::Job)
      ReQL::Datum.new({
        "id"           => [job.type, job.id.to_s],
        "duration_sec" => (Time.utc - job.start_time).total_seconds,
        "type"         => job.type,
        "info"         => job.is_a?(ReQL::QueryJob) ? {
          "query" => job.term.inspect,
        } : job.is_a?(ReQL::TableScanJob) ? {
          "table" => job.table.name,
          "db"    => job.table.db_name,
        } : nil,
      }).hash_value
    end

    def scan(&block : Hash(String, ReQL::Datum) ->)
      jobs = @manager.job_manager.lock.synchronize { @manager.job_manager.jobs.dup }
      jobs.each_value do |job|
        yield encode(job)
      end
    end
  end
end
