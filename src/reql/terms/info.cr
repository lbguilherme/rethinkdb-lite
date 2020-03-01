require "../term"

module ReQL
  class InfoTerm < Term
    infix_inspect "info"

    def check
      expect_args 1
    end
  end

  class Evaluator
    def eval_term(term : InfoTerm)
      target = eval(term.args[0])

      case target.reql_type
      when "TABLE"
        table = target.as_table
        storage = table.storage

        Datum.new({
          "db" => {
            "id"   => "", # TODO
            "name" => table.db.name,
            "type" => "DB",
          },
          "doc_count_estimates" => [
            storage.is_a?(Storage::PhysicalTable) ? storage.estimated_count : 0,
          ],
          "id"          => "", # TODO
          "indexes"     => storage.is_a?(Storage::PhysicalTable) ? storage.get_index_list : [] of String,
          "name"        => table.name,
          "primary_key" => storage.primary_key,
          "type"        => "TABLE",
        })
      else
        raise "BUG: .info() not implemented for #{target.reql_type}"
      end
    end
  end
end
