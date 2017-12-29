require "uuid"

module ReQL
  class InsertTerm < Term
    register_type INSERT
    infix_inspect "insert"
  end

  class Evaluator
    def eval(term : InsertTerm)
      table = eval term.args[0]
      expect_type table, Table
      table.check

      datum = eval term.args[1]

      docs = [] of Datum::Type
      case datum
      when DatumArray
        docs = datum.value
      when DatumObject
        docs = [datum.value] of Datum::Type
      else
        raise QueryLogicError.new("Expected type OBJECT but found #{datum.class.reql_name}")
      end

      inserted = 0i64
      errors = 0i64
      generated_keys = nil
      first_error = nil

      docs.each do |obj|
        begin
          unless obj.is_a? Hash
            raise QueryLogicError.new("Expected type OBJECT but found #{Datum.wrap(obj).class.reql_name}")
          end
          unless obj.has_key? "id"
            id = UUID.random.to_s
            obj["id"] = id
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

      result = Hash(String, Datum::Type).new
      result["deleted"] = 0i64
      result["replaced"] = 0i64
      result["skipped"] = 0i64
      result["unchanged"] = 0i64
      result["inserted"] = inserted
      result["errors"] = errors
      if first_error
        result["first_error"] = first_error
      end
      if generated_keys
        result["generated_keys"] = generated_keys
      end

      Datum.wrap(result)
    end
  end
end
