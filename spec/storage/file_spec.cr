require "spec"
require "../../src/storage/*"
require "random/secure"
require "file_utils"

FileUtils.rm_rf "/tmp/rethinkdb-lite/storage/"
FileUtils.mkdir_p "/tmp/rethinkdb-lite/storage/"

describe Storage::DatabaseFile do
  it "accepts writes and reads" do
    db = Storage::DatabaseFile.create(random_file)

    pos = 0u32
    db.write do |w|
      page = w.alloc('E')
      pos = page.pos
      put_str(page, "Hello!")
      w.put(page)
    end

    db.read do |r|
      get_str(r.get(pos)).should eq "Hello!"
    end
  end

  it "takes multiple writes" do
    db = Storage::DatabaseFile.create(random_file)

    pos = 0u32
    db.write do |w|
      page = w.alloc('E')
      pos = page.pos
      put_str(page, "Hello 1!")
      w.put(page)
      put_str(page, "Hello 2!")
      w.put(page)
      put_str(page, "Hello 3!")
      w.put(page)
    end

    db.read do |r|
      get_str(r.get(pos)).should eq "Hello 3!"
    end
  end

  it "persists writes across file opens" do
    file = random_file
    db = Storage::DatabaseFile.create(file)

    pos = 0u32
    db.write do |w|
      page = w.alloc('E')
      pos = page.pos
      put_str(page, "Hello!")
      w.put(page)
    end

    db.close
    db = Storage::DatabaseFile.open(file)

    db.read do |r|
      get_str(r.get(pos)).should eq "Hello!"
    end
  end

  it "rolls back in case a write aborts" do
    db = Storage::DatabaseFile.create(random_file)

    pos = 0u32
    db.write do |w|
      page = w.alloc('E')
      pos = page.pos
      put_str(page, "Hello 1!")
      w.put(page)
    end

    expect_raises(MockException, "pew!") do
      db.write do |w|
        page = w.get(pos)
        get_str(page).should eq "Hello 1!"
        put_str(page, "Hello 2!")
        w.put(page)
        get_str(page).should eq "Hello 2!"
        raise MockException.new("pew!")
      end
    end

    db.read do |r|
      get_str(r.get(pos)).should eq "Hello 1!"
    end
  end

  it "doesnt affects on-going reads with writes" do
    db = Storage::DatabaseFile.create(random_file)

    pos = 0u32
    db.write do |w|
      page = w.alloc('E')
      pos = page.pos
      put_str(page, "Hello 1!")
      w.put(page)
    end

    db.read do |r|
      get_str(r.get(pos)).should eq "Hello 1!"

      db.write do |w|
        get_str(w.get(pos)).should eq "Hello 1!"

        page = w.get(pos)
        put_str(page, "Hello 2!")
        w.put(page)

        get_str(r.get(pos)).should eq "Hello 1!"
        get_str(w.get(pos)).should eq "Hello 2!"
      end

      get_str(r.get(pos)).should eq "Hello 1!"
    end

    db.read do |r|
      get_str(r.get(pos)).should eq "Hello 2!"
    end
  end
end

# Helpers

class MockException < Exception
end

def random_file
  "/tmp/rethinkdb-lite/storage/#{Random::Secure.hex}.db"
end

def get_str(page)
  ptr = page.pointer.as(UInt8*) + 200
  String.new(ptr)
end

def put_str(page, str)
  ptr = page.pointer.as(UInt8*) + 200
  slice = str.to_slice
  slice.copy_to(ptr, slice.size)
end
