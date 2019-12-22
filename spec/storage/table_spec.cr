require "spec"
require "../../src/storage/*"
require "random/secure"
require "file_utils"

FileUtils.rm_rf "/tmp/rethinkdb-lite/storage/"
FileUtils.mkdir_p "/tmp/rethinkdb-lite/storage/"

describe Storage::StoredTable do
  it "can insert and read documents with table" do
    table = Storage::StoredTable.create(random_file)

    objs = [
      {"id" => 47, "a": "hmm", "b": 13},
      {"id" => "47", "value": [1, 2, 3]},
      {"id" => (1..3500).to_a, "lala": ("a".."z").to_a},
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
    file = random_file
    table = Storage::StoredTable.create(file)

    300.times do |i|
      obj = {"id" => i, "v" => i}
      table.insert(obj)
    end

    300.times do |i|
      obj = {"id" => i, "v" => i}
      table.get(i).should eq obj
    end

    table.close
    table = Storage::StoredTable.open(file)

    300.times do |i|
      obj = {"id" => i, "v" => i}
      table.get(i).should eq obj
    end
  end

  it "can apply replaces to a document" do
    table = Storage::StoredTable.create(random_file)

    5.times do |i|
      obj = {"id" => i, "v" => 0}
      table.insert(obj)
    end

    10.times do |j|
      5.times do |i|
        obj = {"id" => i, "v" => j}
        table.get(i).should eq obj

        table.replace(i) do |old_obj|
          old_obj.should eq obj
          {"id" => old_obj.not_nil!["id"], "v" => old_obj.not_nil!["v"].value.as(Int).to_i + 1}
        end

        table.get(i).not_nil!["v"].should eq j + 1
      end
    end
  end
end

# Helpers

def random_file
  "/tmp/rethinkdb-lite/storage/#{Random::Secure.hex}.db"
end
