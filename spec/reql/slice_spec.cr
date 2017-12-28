require "spec"
require "../../src/reql/*"

include ReQL::DSL

describe ReQL do
  it "can take a slice of an array" do
    r([0, 1, 2, 3, 4]).slice(1, 3).run.value.should eq [1, 2]
    r([0, 1, 2, 3, 4]).limit(3).run.value.should eq [0, 1, 2]
    r([0, 1, 2, 3, 4]).limit(30).run.value.should eq [0, 1, 2, 3, 4]
    r([0, 1, 2, 3, 4]).skip(3).run.value.should eq [3, 4]
    r([0, 1, 2, 3, 4]).skip(30).run.value.should eq [] of Int64
  end

  it "can count a slice of an array" do
    r([0, 1, 2, 3, 4]).slice(1, 3).count.run.value.should eq 2
    r([0, 1, 2, 3, 4]).limit(3).count.run.value.should eq 3
    r([0, 1, 2, 3, 4]).limit(30).count.run.value.should eq 5
    r([0, 1, 2, 3, 4]).skip(3).count.run.value.should eq 2
    r([0, 1, 2, 3, 4]).skip(30).count.run.value.should eq 0
  end

  it "can take a slice of a stream" do
    r.range(5).slice(1, 3).run.value.should eq [1, 2]
    r.range(5).limit(3).run.value.should eq [0, 1, 2]
    r.range(5).limit(30).run.value.should eq [0, 1, 2, 3, 4]
    r.range(5).skip(3).run.value.should eq [3, 4]
    r.range(5).skip(30).run.value.should eq [] of Int64
  end

  it "can count a slice of a stream" do
    r.range(5).slice(1, 3).count.run.value.should eq 2
    r.range(5).limit(3).count.run.value.should eq 3
    r.range(5).limit(30).count.run.value.should eq 5
    r.range(5).skip(3).count.run.value.should eq 2
    r.range(5).skip(30).count.run.value.should eq 0
  end

  it "can take a slice of an infinite stream" do
    r.range.skip(10).limit(2).run.value.should eq [10, 11]
  end
end
