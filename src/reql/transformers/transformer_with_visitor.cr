require "../term"
require "./transformer"

abstract struct ReQL::TransformerWithVisitor < ReQL::Transformer
  def initialize(root_term : ReQL::Term::Type)
    super(root_term)
    visit(root_term)
    finish_visit
  end

  protected def visit(hsh : Hash)
    hsh.each_value { |value| visit value }
  end

  protected def visit(val : Bool | String | Bytes | Float64 | Int64 | Int32 | Time | Nil)
  end

  protected def visit(term : ReQL::Term)
    term.args.each { |arg| visit arg }
  end

  protected def finish_visit
  end
end
