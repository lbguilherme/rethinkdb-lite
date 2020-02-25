require "./virtual_table"

module Storage
  struct VirtualJobsTable < VirtualTable
    def initialize(manager : Manager)
      super("jobs", manager)
    end

    def get(key)
      nil
    end

    def scan(&block : Hash(String, ReQL::Datum) ->)
    end
  end
end
