require "spec"
require "../src/storage/*"
require "secure_random"

system "rm -rf /tmp/dblite"
system "mkdir /tmp/dblite"

describe DatabaseFile do
  it "can insert and read documents with table" do
    db = DatabaseFile.create(random_file)
    table = make_table(db)

    objs = [
      {"id" => 47, "a": "hmm", "b": 13},
      {"id" => "47", "value": [1, 2, 3]},
      {"id" => (1..3500).to_a, "lala": ("a".."z").to_a}
    ]

    db.write do |w|
      objs.each {|obj| table.insert(w, obj) }
    end

    db.read do |r|
      objs.each {|obj| table.get(r, obj["id"]).should eq obj }

      table.get(r, 5).should eq nil
    end
  end

  it "can handle several objects in the table" do
    db = DatabaseFile.create(random_file)
    table = make_table(db)

    300.times do |i|
      obj = {"id" => i, "v" => i}
      db.write do |w|
        table.insert(w, obj)
      end
    end

    db.read do |r|
      300.times do |i|
        obj = {"id" => i, "v" => i}
        table.get(r, i).should eq obj
      end
    end
  end
end

# Helpers

def make_table(db)
  table = Table.new(0u32)
  db.write do |w|
    table = Table.create(w)
  end
  table
end

def random_file
  "/tmp/dblite/#{SecureRandom.hex}.db"
end
