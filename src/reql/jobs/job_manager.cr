require "./query_job"

class ReQL::JobManager
  getter jobs = Hash(UUID, Job).new
  getter lock = Mutex.new

  def run_query(evaluator : Evaluator, term : Term::Type)
    QueryJob.new(self, evaluator, term).result
  end
end
