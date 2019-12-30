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
      after_commit = nil

      table.replace(key) do |old|
        if old.nil?
          after_commit = -> { @skipped += 1 }
        else
          after_commit = -> { @deleted += 1 }
        end
        nil
      end

      after_commit.try &.call
    rescue err
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

      table.replace(row[primary_key]) do |old|
        if old.nil?
          row
        else
          pretty_old = JSON.build(4) { |builder| old.to_json(builder) }
          pretty_row = JSON.build(4) { |builder| row.to_json(builder) }
          raise ReQL::OpFailedError.new("Duplicate primary key `#{primary_key}`:\n#{pretty_old}\n#{pretty_row}")
        end
      end

      @inserted += 1
    rescue err
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
