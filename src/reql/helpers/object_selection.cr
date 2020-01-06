require "../executor/datum"

module ReQL
  class ObjectSelection
    @complete_fields = Set(String).new
    @partial_fields = Hash(String, ObjectSelection).new { |hash, key| hash[key] = ObjectSelection.new }

    def add(datum : Datum)
      if field_name = datum.string_value?
        @complete_fields << field_name
        @partial_fields.delete(field_name)
      elsif hash = datum.hash_value?
        hash.each do |(field, datum_value)|
          next if @complete_fields.includes?(field)
          if datum_value.bool_value? == true
            @complete_fields << field
            @partial_fields.delete(field)
          else
            @partial_fields[field].add(datum_value)
          end
        end
      else
        raise QueryLogicError.new("Invalid object selection argument `#{datum.value}`")
      end
    end

    def reject_on_object(obj : Datum)
      hash = obj.hash_value?
      return obj unless hash
      Datum.new(hash.reject do |field|
        @complete_fields.includes?(field)
      end.map do |(field, value)|
        {field, @partial_fields.has_key?(field) ? @partial_fields[field].reject_on_object(value) : value}
      end.to_h)
    end

    def select_on_object(obj : Datum)
      hash = obj.hash_value?
      return obj unless hash
      Datum.new(hash.select do |field|
        @complete_fields.includes?(field)
      end.map do |(field, value)|
        {field, @partial_fields.has_key?(field) ? @partial_fields[field].select_on_object(value) : value}
      end.to_h)
    end
  end
end
