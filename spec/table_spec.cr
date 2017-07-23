require "spec"
require "../src/storage/*"
require "secure_random"

system "rm -rf /tmp/dblite"
system "mkdir /tmp/dblite"

describe DatabaseFile do
  it "can insert and read documents with table" do
    table = Table.create(random_file)

    objs = [
      {"id" => 47, "a": "hmm", "b": 13},
      {"id" => "47", "value": [1, 2, 3]},
      {"id" => (1..3500).to_a, "lala": ("a".."z").to_a}
    ]

    objs.each do |obj|
      table.insert(obj)
    end

    objs.each do |obj|
      table.get(obj["id"]).should eq obj
    end

    table.get(5).should eq nil
  end

  it "can handle several objects in the table" do
    table = Table.create(random_file)

    300.times do |i|
      obj = {"id" => i, "v" => i}
      table.insert(obj)
    end

    300.times do |i|
      obj = {"id" => i, "v" => i}
      table.get(i).should eq obj
    end
  end
end

# Helpers

def random_file
  "/tmp/dblite/#{SecureRandom.hex}.db"
end
