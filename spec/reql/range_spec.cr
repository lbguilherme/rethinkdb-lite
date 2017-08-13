require "spec"
require "../../src/reql/*"

include ReQL::DSL

describe ReQL do
  it "finite ranges iterates from begin to end" do
    r.range(5, 176).run.value.should eq (5...176).to_a
    r.range(51, 58).run.value.should eq (51...58).to_a
    r.range(10, 10).run.value.should eq [] of Int64
    r.range(10, 2).run.value.should eq [] of Int64

    r.range(17).run.value.should eq (0...17).to_a
    r.range(0).run.value.should eq [] of Int64
  end

  it "finite ranges has consistent count" do
    r.range(5, 176).count.run.value.should eq (5...176).size
    r.range(51, 58).count.run.value.should eq (51...58).size
    r.range(10, 10).count.run.value.should eq 0
    r.range(10, 2).count.run.value.should eq 0

    r.range(17).count.run.value.should eq (0...17).size
    r.range(0).count.run.value.should eq 0
  end

  it "infinite ranges iterates from zero to infinity" do
    stream = r.range.run.as ReQL::Stream
    stream.start_reading
    1000.times do |i|
      stream.next_val.should eq({i.to_i64})
    end
    stream.finish_reading
  end
end
