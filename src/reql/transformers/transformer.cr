require "../term"

abstract struct ReQL::Transformer
  def self.transform(term : ReQL::Term::Type)
    term = ReQL::GroupTransformer.new(term).transform
    term = ReQL::SimplifyVariablesTransformer.new(term).transform
  end

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
    result = {} of String => ReQL::Term::Type
    hsh.each do |(k, v)|
      result[k] = transform(v)
    end
    result.as(ReQL::Term::Type)
  end

  protected def transform(val : Bool | String | Bytes | Float64 | Int64 | Int32 | Time | Nil) : ReQL::Term::Type
    val
  end

  protected def transform(term : ReQL::Term) : ReQL::Term::Type
    term = term.dup
    term.args = term.args.map { |e| transform(e).as(ReQL::Term::Type) }
    term
  end
end

require "./transformer_with_visitor"
require "./*"
