require "spec"
require "../../src/reql/*"

include ReQL::DSL

describe ReQL do
  it "maps datum array to datum array" do
    r([1, 2, 3]).map { |x| x }.run.value.should eq (1..3).to_a
    r([1, 2, 3]).map { |x| {"value" => x.as(R::Type)}.as(R::Type) }.run.value.should eq (1..3).map { |x| {"value" => x} }
    r([1, 2, 3]).map { |x| x }.count.run.value.should eq 3
  end
end
