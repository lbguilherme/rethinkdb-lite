require "spec"
require "../../src/reql/*"

include ReQL::DSL

macro inspect_check(expr)
  {{expr.id}}.inspect.should eq {{expr}}
end

describe ReQL do
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
end
