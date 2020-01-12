require "../term"

module ReQL
  class FuncTerm < Term
    def initialize(args, options)
      super(args, options)

      mentioned_variables = Set(Int64).new
      FuncTerm.visit_variables(self) do |var|
        mentioned_variables.add(var)
      end

      args = @args[0].as(Array)
      until args.size == 0 || mentioned_variables.includes? args.last
        args.pop
      end

      @args[0] = args
    end

    def inspect(io)
      vars = @args[0].as(Array)
      body = @args[1]
      if vars.size == 1
        io << "var_" << vars[0] << " => "
      else
        io << "("
        io << vars.map { |i| "var_#{i}" }.join(", ")
        io << ") => "
      end
      body.inspect(io)
    end

    def check
      expect_args 2
    end

    def self.visit_variables(term, &block : Int64 ->)
      case term
      when Term
        term.args.each { |arg| visit_variables arg, &block }
        if term.is_a? VarTerm
          block.call term.args[0].as(Int64)
        end
      when Array
        term.each { |e| visit_variables e, &block }
      when Hash
        term.each { |(_, v)| visit_variables v, &block }
      end
    end
  end

  class Evaluator
    def eval_term(term : FuncTerm)
      ReqlFunc.new(term.args[0].as(Array).map { |x| x.as(Int64) }, term.args[1])
    end
  end
end
