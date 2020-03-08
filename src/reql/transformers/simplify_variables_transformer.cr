require "../term"
require "./transformer_with_visitor"

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
    ReQL::VarTerm.new([@mapping[term.args[0].as(Int64)].as(ReQL::Term::Type)])
  end

  protected def transform(term : ReQL::FuncTerm) : ReQL::Term::Type
    term = super(term).as(ReQL::FuncTerm)
    ReQL::FuncTerm.new([
      ReQL::MakeArrayTerm.new(
        term.args[0].as(ReQL::MakeArrayTerm).args.map { |arg| @mapping[arg.as(Int64)].as(ReQL::Term::Type) }
      ).as(ReQL::Term::Type),
      term.args[1].as(ReQL::Term::Type),
    ])
  end
end
