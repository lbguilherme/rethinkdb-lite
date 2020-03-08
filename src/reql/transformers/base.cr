require "../term"

abstract struct ReQL::Transformer
  def initialize(@root_term : ReQL::Term::Type)
  end

  def transform
    should_transform(@root_term) ? transform(@root_term) : @root_term
  end

  protected def should_transform(hsh : Hash) : Bool
    hsh.each_value do |value|
      return true if should_transform(value)
    end
    false
  end

  protected def should_transform(val : Bool | String | Bytes | Float64 | Int64 | Int32 | Time | Nil) : Bool
    false
  end

  protected def should_transform(term : ReQL::Term) : Bool
    term.args.any? { |arg| should_transform arg }
  end

  protected def transform(hsh : Hash) : ReQL::Term::Type
    hsh.each do |(k, v)|
      hsh[k] = transform(v)
    end
    hsh
  end

  protected def transform(val : Bool | String | Bytes | Float64 | Int64 | Int32 | Time | Nil) : ReQL::Term::Type
    val
  end

  protected def transform(term : ReQL::Term) : ReQL::Term::Type
    term.args.map! { |e| transform(e) }
    term
  end
end

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
