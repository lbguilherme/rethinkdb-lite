module ReQL
  class TableWriter
    @deleted = 0
    @replaced = 0
    @skipped = 0
    @unchanged = 0
    @inserted = 0
    @errors = 0
    @first_error : String?
    @generated_keys = [] of String

    def delete(table : Storage::AbstractTable, key : Datum)
      if table.delete(key)
        @deleted += 1
      else
        @skipped += 1
      end
    rescue err : RuntimeError
      @errors += 1
      @first_error ||= err.message
    end

    def insert(table : Storage::AbstractTable, row : Hash(String, Datum))
      primary_key = table.primary_key
      unless row.has_key? primary_key
        id = UUID.random.to_s
        row[primary_key] = Datum.new(id)
        @generated_keys << id
      end
      table.insert(row)
      @inserted += 1
    rescue err : RuntimeError
      @errors += 1
      @first_error ||= err.message
    end

    def summary
      result = Hash(String, Datum).new

      result["deleted"] = Datum.new(@deleted)
      result["replaced"] = Datum.new(@replaced)
      result["skipped"] = Datum.new(@skipped)
      result["unchanged"] = Datum.new(@unchanged)
      result["inserted"] = Datum.new(@inserted)
      result["errors"] = Datum.new(@errors)

      if @first_error
        result["first_error"] = Datum.new(@first_error)
      end

      if !@generated_keys.empty?
        result["generated_keys"] = Datum.new(@generated_keys)
      end

      Datum.new(result)
    end
  end
end
