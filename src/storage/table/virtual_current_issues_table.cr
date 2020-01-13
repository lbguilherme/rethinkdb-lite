require "./virtual_table"

module Storage
  struct VirtualCurrentIssuesTable < VirtualTable
    def initialize(manager : Manager)
      super("current_issues", manager)
    end

    def get(key)
      nil
    end

    def scan(&block : Hash(String, ReQL::Datum) ->)
    end
  end
end
