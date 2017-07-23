module ReQL
  class InsertTerm < Term
    register_type INSERT
    infix_inspect "insert"
  end

  class Term
    def self.eval(term : InsertTerm)
      table = eval term.args[0]
      expect_type table, Table
      obj = eval term.args[1]
      expect_type obj, Datum
      table.insert(obj.value)
      Datum.new(Hash(String, Datum::Type){"inserted" => 1i64})
    end
  end
end
