require "../term"
require "./base"

struct ReQL::GroupTransformer < ReQL::Transformer
  protected def should_transform(term : ReQL::GroupTerm)
    true
  end

  protected def transform(term : ReQL::Term) : ReQL::Term::Type
    term = super(term)

    if term.is_a? ReQL::UngroupTerm
      return term
    end

    idx = term.args.index { |arg| arg.is_a? ReQL::GroupTerm }
    return term unless idx

    group = term.args[idx].as(ReQL::GroupTerm)

    if group.args.size == 2
      var = R.make_var_i
      term.args[idx] = ReQL::VarTerm.new([var.as(ReQL::Term::Type)])
      group.args << ReQL::FuncTerm.new([
        ReQL::MakeArrayTerm.new([var.as(ReQL::Term::Type)]).as(ReQL::Term::Type),
        term.as(ReQL::Term::Type),
      ]).as(ReQL::Term::Type)

      return group
    elsif group.args.size == 3 && (func = group.args[2].as?(ReQL::FuncTerm))
      term.args[idx] = func.args[1]
      func.args[1] = term

      return group
    else
      return term
    end
  end
end
