require "../term"

module ReQL
  class ContainsTerm < Term
    infix_inspect "contains"

    def check
      expect_args_at_least 2
    end
  end

  class Evaluator
    def eval(term : ContainsTerm)
      target = eval(term.args[0])

      predicates = term.args[1..-1].map { |arg| eval(arg) }
      found = predicates.map { false }
      count_found = 0

      target.each do |val|
        val = val.as_datum
        predicates.each_with_index do |predicate, index|
          next if found[index]

          if predicate.is_a?(Func) ? predicate.eval(self, {val}) : predicate.as_datum == val
            found[index] = true
            count_found += 1
          end
        end
        break if count_found == predicates.size
      end

      Datum.new(count_found == predicates.size)
    end
  end
end
