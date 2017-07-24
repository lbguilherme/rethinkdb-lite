module ReQL
  abstract class Stream
    def self.reql_name
      "STREAM"
    end

    def to_datum_array
      start_reading
      list = [] of ReQL::Datum::Type
      while tup = next_row
        list << tup[0]
      end
      finish_reading
      DatumArray.new(list)
    end

    def value
      to_datum_array.value
    end
  end
end
