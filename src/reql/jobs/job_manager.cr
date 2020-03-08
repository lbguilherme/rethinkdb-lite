require "./job"

class ReQL::JobManager
  getter jobs = Hash(UUID, Job).new
  getter lock = Mutex.new
end
