require "uuid"

abstract class ReQL::Job
  getter id = UUID.random
  getter start_time = Time.utc
  getter running = true

  def initialize(@job_manager : JobManager)
    @job_manager.lock.synchronize do
      @job_manager.jobs[@id] = self
    end
  end

  def finish_job
    @running = false
    @job_manager.lock.synchronize do
      @job_manager.jobs.delete(@id)
    end
  end

  abstract def type : String
end
