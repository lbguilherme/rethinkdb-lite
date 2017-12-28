require "./term"

module ReQL
  class Query
    @term : Term::Type
    @profile : Bool

    def initialize(@id : UInt64, json : JSON::Type, options : Hash(String, JSON::Type)?)
      @term = Term.parse(json)
      @profile = options.try &.["profile"]?.try &.as?(Bool) || false
      puts
      p @term
    end

    def run
      Evaluator.new.eval @term
    end

    def profile?
      @profile
    end
  end
end
