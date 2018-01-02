require "./driver/*"
include RethinkDB::DSL

conn = r.connect("172.17.0.2")
require "spec"

p r.expr(42).run(conn)




class X < Exception
end

def foo(num)
  unless num.is_a? Int
    raise X.new "not a number"
  end

  Val.new(num)
end

class Val
  def initialize(@b)
  end
  def bar(x)
  end
end

expect_raises(X) do
  foo("foo").bar(nil).baz
end
