require "../../src/driver/*"
require "../../src/reql/transformers/*"
require "spec"
include RethinkDB::DSL

def check_transform(transformer, source, expected)
  source = source.val
  expected = expected.val

  source = transformer.new(source).transform
  source = ReQL::SimplifyVariablesTransformer.new(source).transform
  expected = ReQL::SimplifyVariablesTransformer.new(expected).transform

  source.should eq expected
end

describe ReQL::Transformer do
  describe ReQL::GroupTransformer do
    it "leaves a single group unchanged" do
      check_transform(
        ReQL::GroupTransformer,
        r.range(10).group { |x| x % 2 },
        r.range(10).group { |x| x % 2 }
      )
    end

    it "transforms a single expression after group" do
      check_transform(
        ReQL::GroupTransformer,
        r.range(10).group { |x| x % 2 }.sum,
        r.range(10).group(r { |x| x % 2 }, r { |g| g.sum })
      )
    end

    it "transforms multiple terms into group" do
      check_transform(
        ReQL::GroupTransformer,
        r.range(10).group { |x| x % 2 }.sum.add(1),
        r.range(10).group(r { |x| x % 2 }, r { |g| g.sum.add(1) })
      )
    end

    it "transformation stops at ungroup" do
      check_transform(
        ReQL::GroupTransformer,
        r.range(10).group { |x| x % 2 }.sum.add(1).ungroup.add(2),
        r.range(10).group(r { |x| x % 2 }, r { |g| g.sum.add(1) }).ungroup.add(2)
      )
    end
  end
end
