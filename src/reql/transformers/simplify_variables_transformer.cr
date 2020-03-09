require "../term"
require "./base"

struct ReQL::SimplifyVariablesTransformer < ReQL::Transformer
  @next_value = 0i64
  @mapping : Hash(Int64, Int64)
  @transformed_vars = Set(ReQL::VarTerm).new

  def initialize(root_term : ReQL::Term::Type)
    super(root_term)
    @mapping = Hash(Int64, Int64).new { |h, k| h[k] = (@next_value += 1) }
  end

  protected def should_transform(term : ReQL::FuncTerm)
    true
  end

  protected def transform(term : ReQL::VarTerm) : ReQL::Term::Type
    return term if @transformed_vars.includes?(term)
    term.args[0] = @mapping[term.args[0].as(Int64)]
    @transformed_vars << term
    term
  end

  protected def transform(term : ReQL::FuncTerm) : ReQL::Term::Type
    term = super(term).as(ReQL::FuncTerm)
    term.args[0].as(MakeArrayTerm).args.map! { |arg| @mapping[arg.as(Int64)] }
    term
  end
end
