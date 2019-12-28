require "uuid"

module ReQL
  class DeleteTerm < Term
    register_type DELETE
    infix_inspect "delete"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : DeleteTerm)
      source = eval(term.args[0])

      deleted = 0i64

      source.each do |obj|
        row = obj.as_row
        row.table.delete(row.key)
        deleted += 1
      end

      result = Hash(String, Datum).new
      result["deleted"] = Datum.new(deleted)
      result["replaced"] = Datum.new(0)
      result["skipped"] = Datum.new(0)
      result["unchanged"] = Datum.new(0)
      result["inserted"] = Datum.new(0)
      result["errors"] = Datum.new(0)

      Datum.new(result)
    end
  end
end
