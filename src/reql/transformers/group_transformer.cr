require "../term"
require "./base"

struct ReQL::GroupTransformer < ReQL::Transformer
  protected def should_transform(term : ReQL::GroupTerm)
    true
  end

  protected def transform(term : ReQL::Term) : ReQL::Term::Type
    args = term.args.map { |e| transform(e).as(ReQL::Term::Type) }

    if term.is_a? ReQL::UngroupTerm
      return term.class.new(args, term.options)
    end

    idx = args.index { |arg| arg.is_a? ReQL::GroupTerm }
    return term.class.new(args, term.options) unless idx

    group_args = args[idx].as(ReQL::GroupTerm).args

    if group_args.size == 2
      var = R.make_var_i
      args[idx] = ReQL::VarTerm.new([var.as(ReQL::Term::Type)])
      group_args << ReQL::FuncTerm.new([
        ReQL::MakeArrayTerm.new([var.as(ReQL::Term::Type)]).as(ReQL::Term::Type),
        term.class.new(args, term.options).as(ReQL::Term::Type),
      ]).as(ReQL::Term::Type)

      return ReQL::GroupTerm.new(group_args)
    elsif group_args.size == 3 && (func = group_args[2].as?(ReQL::FuncTerm))
      args[idx] = func.args[1]
      group_args[2] = ReQL::FuncTerm.new([
        func.args[0].as(ReQL::Term::Type),
        term.class.new(args, term.options).as(ReQL::Term::Type),
      ])

      return ReQL::GroupTerm.new(group_args)
    else
      return term.class.new(args, term.options)
    end
  end
end
