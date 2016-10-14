defmodule DeselTest.Parser do
  use ExUnit.Case
  doctest Desel

  use Parselix
  import Desel.Parser
  alias Desel.AST

  test "element and set" do
    target = "@label"
    parser = element(true)
    ast = %AST.Element{token: "@label", label: "label"}
    assert parser |> parse(target) |> elem(1) == ast

    target = "label"
    parser = set
    ast = %AST.Set{token: "label", label: "label"}
    assert parser |> parse(target) |> elem(1) == ast
  end

  test "opt_not" do
    target = "! %label"
    parser = set(true) |> opt_not
    ast = %AST.Not{token: "! ", target: %AST.Set{token: "%label", label: "label"}}
    assert parser |> parse(target) |> elem(1) == ast

    target = "!label"
    parser = element |> opt_not
    ast = %AST.Not{token: "!", target: %AST.Element{token: "label", label: "label"}}
    assert parser |> parse(target) |> elem(1) == ast
  end
end
