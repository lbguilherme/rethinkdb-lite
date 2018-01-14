require "spec"
require "../../src/driver/*"

include RethinkDB::DSL

macro inspect_check(expr)
  {{expr.id}}.inspect.should eq {{expr}}
end

describe RethinkDB do
  it "inspects r.table().get()" do
    inspect_check %{r.table("test").get(nil)}
    inspect_check %{r.table("test").get(123)}
    inspect_check %{r.table("test").get("123")}
    inspect_check %{r.table("test").get([1, 2, "aa"])}
    inspect_check %{r.table("test").get(1.5)}
    inspect_check %{r.table("test").get({"x" => 5})}
  end

  it "inspects r.table().insert()" do
    inspect_check %{r.table("test").insert({"x" => 5})}
  end

  it "inspects r.table().count()" do
    inspect_check %{r.table("test").count()}
  end

  it "inspects r.range()" do
    inspect_check %{r.range()}
    inspect_check %{r.range(10)}
    inspect_check %{r.range(5, 30)}
  end

  # it "inspects r.map()" do
  #   R.reset_next_var_i
  #   r.range(10).map { |x| x }.inspect.should eq "r.range(10).map(var_1 => var_1)"
  # end
end
