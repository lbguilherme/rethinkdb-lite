require "../term"
require "./base"

struct ReQL::SimplifyVariablesTransformer < ReQL::TransformerWithVisitor
  @variables = Set(Int64).new
  @mapping = {} of Int64 => Int64

  protected def should_transform(term : ReQL::FuncTerm)
    true
  end

  protected def visit(term : ReQL::FuncTerm)
    super(term)
    term.args[0].as(ReQL::MakeArrayTerm).args.each do |arg|
      @variables << arg.as(Int64)
    end
  end

  protected def visit(term : ReQL::VarTerm)
    super(term)
    @variables << term.args[0].as(Int64)
  end

  protected def finish_visit
    @variables.to_a.sort.each_with_index do |var, i|
      @mapping[var] = (i + 1).to_i64
    end
  end

  protected def transform(term : ReQL::VarTerm) : ReQL::Term::Type
    term.args[0] = @mapping[term.args[0].as(Int64)]
    term
  end

  protected def transform(term : ReQL::FuncTerm) : ReQL::Term::Type
    term = super(term).as(ReQL::FuncTerm)
    term.args[0].as(MakeArrayTerm).args.map! { |arg| @mapping[arg.as(Int64)] }
    term
  end
end
