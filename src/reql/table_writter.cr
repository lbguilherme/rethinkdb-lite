module ReQL
  enum Durability
    Hard
    Soft
    Minimal
  end

  class TableWriter
    property created = Atomic(Int32).new(0)
    property tables_created = Atomic(Int32).new(0)
    property config_changes = [] of String # TODO
    property deleted = Atomic(Int32).new(0)
    property replaced = Atomic(Int32).new(0)
    property skipped = Atomic(Int32).new(0)
    property unchanged = Atomic(Int32).new(0)
    property inserted = Atomic(Int32).new(0)
    property errors = Atomic(Int32).new(0)
    property first_error : String?
    property generated_keys = [] of String
    property mutex = Mutex.new

    def delete(table : Storage::AbstractTable, key : Datum, durability : Durability? = nil)
      after_commit = nil

      table.replace(key, durability) do |old|
        if old.nil?
          after_commit = ->{ @skipped.add(1) }
        else
          after_commit = ->{ @deleted.add(1) }
        end
        nil
      end

      after_commit.try &.call
    rescue err
      @errors.add(1)
      @mutex.synchronize do
        @first_error ||= err.message
      end
    end

    private def internal_insert(table : Storage::AbstractTable, row : Hash(String, Datum), durability : Durability? = nil)
      primary_key = table.primary_key
      unless row.has_key? primary_key
        id = UUID.random.to_s
        row[primary_key] = Datum.new(id)
        @mutex.synchronize do
          @generated_keys << id
        end
      end

      table.replace(row[primary_key], durability) do |old|
        if old.nil?
          row
        else
          pretty_old = JSON.build(4) { |builder| old.to_json(builder) }
          pretty_row = JSON.build(4) { |builder| row.to_json(builder) }
          raise ReQL::OpFailedError.new("Duplicate primary key `#{primary_key}`:\n#{pretty_old}\n#{pretty_row}")
        end
      end
    end

    def insert(table : Storage::AbstractTable, row : Hash(String, Datum), durability : Durability? = nil)
      internal_insert(table, row, durability)
      @inserted.add(1)
    rescue err
      @errors.add(1)
      @mutex.synchronize do
        @first_error ||= err.message
      end
    end

    def create_table(table : Storage::VirtualTableConfigTable, row : Hash(String, Datum))
      row["id"] = Datum.new(UUID.random.to_s)
      internal_insert(table, row)
      @tables_created.add(1)
    end

    def create_index(table : Storage::PhysicalTable, name : String, function : Func)
      table.create_index(name, function)
      @created.add(1)
    end

    def atomic_update(table : Storage::AbstractTable, key : Datum, durability : Durability? = nil)
      after_commit = nil
      primary_key = table.primary_key

      table.replace(key, durability) do |old|
        if old.nil?
          after_commit = ->{ @skipped.add(1) }
          nil
        else
          row = yield old
          row = ReQL.merge_objects(old, row)

          if row == old
            after_commit = ->{ @unchanged.add(1) }
            old
          elsif row[primary_key] != old[primary_key]
            pretty_old = JSON.build(4) { |builder| old.to_json(builder) }
            pretty_row = JSON.build(4) { |builder| row.to_json(builder) }
            raise ReQL::OpFailedError.new("Primary key `#{primary_key}` cannot be changed:\n#{pretty_old}\n#{pretty_row}")
          else
            after_commit = ->{ @replaced.add(1) }
            row
          end
        end
      end

      after_commit.try &.call
    rescue err
      @errors.add(1)
      @mutex.synchronize do
        @first_error ||= err.message
      end
    end

    def merge(other : TableWriter)
      @created.add(other.created.get)
      @tables_created.add(other.tables_created.get)
      @deleted.add(other.deleted.get)
      @replaced.add(other.replaced.get)
      @skipped.add(other.skipped.get)
      @unchanged.add(other.unchanged.get)
      @inserted.add(other.inserted.get)
      @errors.add(other.errors.get)
      @mutex.synchronize do
        @first_error ||= other.first_error
        @generated_keys += other.generated_keys
        @config_changes += other.config_changes
      end
    end

    def summary
      @mutex.synchronize do
        result = Hash(String, Datum).new

        if @created.get != 0
          result["created"] = Datum.new(@created.get)
        end

        if @tables_created.get != 0
          result["tables_created"] = Datum.new(@tables_created.get)
        end

        if @config_changes.size > 0
          result["config_changes"] = Datum.new(@config_changes)
        end

        has_normal_write = @deleted.get != 0 || @errors.get != 0 || @first_error != nil ||
                           @generated_keys.size > 0 || @inserted.get != 0 || @replaced.get != 0 ||
                           @skipped.get != 0 || @unchanged.get != 0

        if result.size == 0 || has_normal_write
          result["deleted"] = Datum.new(@deleted.get)
          result["errors"] = Datum.new(@errors.get)

          if @first_error
            result["first_error"] = Datum.new(@first_error)
          end

          if !@generated_keys.empty?
            result["generated_keys"] = Datum.new(@generated_keys)
          end

          result["inserted"] = Datum.new(@inserted.get)
          result["replaced"] = Datum.new(@replaced.get)
          result["skipped"] = Datum.new(@skipped.get)
          result["unchanged"] = Datum.new(@unchanged.get)
        end

        Datum.new(result)
      end
    end
  end
end
