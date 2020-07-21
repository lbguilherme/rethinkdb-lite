require "./*"

abstract struct ReQL::Transformer
  def self.transform(term : ReQL::Term::Type)
    term = ReQL::GroupTransformer.new(term).transform
    # FIXME:
    # term = ReQL::SimplifyVariablesTransformer.new(term).transform
  end
end
