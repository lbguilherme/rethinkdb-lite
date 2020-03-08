require "./job"
require "../executor/stream"

class ReQL::QueryJob < ReQL::Job
  @future_result : Concurrent::Future(ReQL::AbstractValue)?
  getter term

  def initialize(job_manager, @evaluator : Evaluator, @term : Term::Type)
    super(job_manager)

    @future_result = future do
      begin
        result = @evaluator.eval(term)
        if result.is_a? ReQL::Stream
          ResultStream.new(result, self)
        else
          finish_job
          result
        end
      rescue error
        finish_job
        raise error
      end
    end
  end

  def result
    @future_result.not_nil!.get
  end

  def type : String
    "query"
  end

  struct ResultStream < ReQL::Stream
    @stream : Box(Stream)

    def initialize(stream : Stream, @job : ReQL::QueryJob)
      @stream = Box(Stream).new(stream)
    end

    def start_reading
      raise QueryLogicError.new "Query terminated." unless @job.running
      @stream.object.start_reading
    end

    def next_val
      raise QueryLogicError.new "Query terminated." unless @job.running
      @stream.object.next_val
    end

    def finish_reading
      @stream.object.finish_reading
      @job.finish_job
    end
  end
end
