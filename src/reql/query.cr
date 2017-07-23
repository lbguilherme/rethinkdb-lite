require "./term"

class Query
  def initialize(@id : UInt64, json : JSON::Type, options : Hash(String, JSON::Type)?)
    puts json
    p Term.parse(json)
  end
end
