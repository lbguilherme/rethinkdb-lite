require "../term"

module ReQL
  class BranchTerm < Term
    register_type BRANCH
    infix_inspect "branch"

    def compile
      expect_args_at_least 3
      if @args.size % 2 == 0
        raise QueryLogicError.new "Cannot call `branch` term with an even number of arguments."
      end
    end
  end

  class Evaluator
    def eval(term : BranchTerm)
      (term.args.size//2).times do |i|
        cond = eval(term.args[2*i]).as_datum
        if cond.value
          return eval(term.args[2*i + 1])
        end
      end

      return eval(term.args.last)
    end
  end
end
