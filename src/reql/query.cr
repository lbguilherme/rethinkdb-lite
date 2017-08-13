require "./term"

module ReQL
  class Query
    @term : Term::Type

    def initialize(@id : UInt64, json : JSON::Type, options : Hash(String, JSON::Type)?)
      @term = Term.parse(json)
      p @term
    end

    def run
      Evalutator.new.eval @term
    end
  end
end
