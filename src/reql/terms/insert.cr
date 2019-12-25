require "uuid"

module ReQL
  class InsertTerm < Term
    register_type INSERT
    infix_inspect "insert"
  end

  class Evaluator
    def eval(term : InsertTerm)
      table = eval(term.args[0]).as_table
      table.check

      datum = eval(term.args[1])

      docs = case
             when array = datum.array_value?
               array.map do |e|
                 if hash = e.hash_value?
                   hash
                 else
                   raise QueryLogicError.new("Expected type OBJECT but found #{e.reql_type}")
                 end
               end
             when hash = datum.hash_value?
               [hash]
             else
               raise QueryLogicError.new("Expected type OBJECT but found #{datum.reql_type}")
             end

      inserted = 0i64
      errors = 0i64
      generated_keys = nil
      first_error = nil

      docs.each do |obj|
        begin
          unless obj.has_key? "id"
            id = UUID.random.to_s
            obj["id"] = Datum.new(id)
            generated_keys = [] of Datum::Type unless generated_keys
            generated_keys << id
          end
          table.insert(obj)
        rescue err : RuntimeError
          errors += 1
          first_error ||= err.message
        else
          inserted += 1
        end
      end

      result = Hash(String, Datum).new
      result["deleted"] = Datum.new(0)
      result["replaced"] = Datum.new(0)
      result["skipped"] = Datum.new(0)
      result["unchanged"] = Datum.new(0)
      result["inserted"] = Datum.new(inserted)
      result["errors"] = Datum.new(errors)
      if first_error
        result["first_error"] = Datum.new(first_error)
      end
      if generated_keys
        result["generated_keys"] = Datum.new(generated_keys)
      end

      Datum.new(result)
    end
  end
end
