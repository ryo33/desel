defmodule DeselTest.Data do
  use ExUnit.Case
  doctest Desel.Data

  alias Desel.Data
  alias Desel.AST

  test "from_ast" do
    data = Data.from_ast([])
    assert Map.size(data.sets) == 0

    a1 = [AST.element("a"), AST.expression(:not, AST.element("b")), AST.element("c")]
    a2 = [
      AST.expression(:and, [AST.set("A"), AST.set("C")]),
      AST.set("B"),
      AST.element("x"),
      AST.element("y"),
      AST.element("x"),
    ]
    ast = [
      AST.set_definition(AST.set("A"), a1),
      AST.element_definition(AST.element("c"), [AST.set("B"), AST.set("C")]),
      AST.element_definition(AST.element("d"), [AST.set("B")]),
      AST.element_definition(AST.element("e"), [AST.set("B"), AST.set("C")]),
      AST.set_definition(AST.set("B"), [AST.set("A")]),
      AST.set_definition(AST.set("A"), a2),
      AST.element_definition(AST.element("d"), [AST.expression(:not, AST.set("A")), AST.set("B")]),
    ]
    data = Data.from_ast(ast)

    assert Map.size(data.sets) == 3
    assert Map.get(data.sets, "A") == a1 ++ a2 ++ [AST.expression(:not, AST.element("d"))]
    assert Map.get(data.sets, "B") == [
      AST.element("c"), AST.element("d"), AST.element("e"), AST.set("A"), AST.element("d")]
    assert Map.get(data.sets, "C") == [AST.element("c"), AST.element("e")]
  end

  defp assert_mapset(mapset, list) do
    assert mapset == MapSet.new(list)
  end

  test "sets" do
    {:ok, ast, _, _} = "%% %A %B %C\n" |> Desel.Parser.parse
    data = Data.from_ast(ast)
    sets = Data.sets(data)
    expected = ?A..?C |> Enum.map(&to_string([&1]))
    assert_mapset sets, expected
  end

  test "elements" do
    {:ok, ast, _, _} = """
    %% %A a b c !d %A e
    @a B C
    @f A B
    @@ @g %A @h @i
    """ |> Desel.Parser.parse
    data = Data.from_ast(ast)
    elements = Data.elements(data)
    expected = ?a..?i |> Enum.map(&to_string([&1]))
    assert_mapset elements, expected
  end

  test "elements_by" do
    {:ok, ast, _, _} = """
    %A a b c
    @c B C
    @@ @d B @e B C
    %B %A
    %C %A & %B x y z
    """ |> Desel.Parser.parse
    data = Data.from_ast(ast)
    {:ok, _data, mapset} = Data.elements_by(data, AST.element("a"))
    assert_mapset mapset, ["a"]
    {:ok, _data, a} = Data.elements_by(data, AST.set("A"))
    assert_mapset a, ["a", "b", "c"]
    {:ok, _data, b} = Data.elements_by(data, AST.set("B"))
    assert_mapset b, ["a", "b", "c", "d", "e"]
    {:ok, _data, c} = Data.elements_by(data, AST.set("C"))
    assert_mapset c, ["a", "b", "c", "e", "x", "y", "z"]
    assert Data.elements_by(data, AST.set("X")) == {:error, data, """
    %"X" does not exist.
    """}

    {:ok, ast, _, _} = """
    %A a d
    %B b c e
    %C b c e f
    %D a c e f g
    %E c f g

    %"D-B-A" %D - %B - %A
    %"B&C&D" %B & %C & %D
    %"!(D-B)" !(%D - %B)
    %"!(!B)" !(!%B)
    """ |> Desel.Parser.parse
    data = Data.from_ast(ast)
    {:ok, _data, mapset} = Data.elements_by(data, data.sets["D-B-A"] |> Enum.at(0))
    assert_mapset mapset, ["f", "g"]
    {:ok, _data, mapset} = Data.elements_by(data, data.sets["B&C&D"] |> Enum.at(0))
    assert_mapset mapset, ["c", "e"]
    {:ok, _data, mapset} = Data.elements_by(data, data.sets["!(D-B)"] |> Enum.at(0))
    assert_mapset mapset, ["b", "c", "d", "e"]
    {:ok, _data, mapset} = Data.elements_by(data, data.sets["!(!B)"] |> Enum.at(0))
    assert_mapset mapset, ["b", "c", "e"]

    {:ok, ast, _, _} = """
    %% %A %B (%C) %C (%D) %D (%E %A) %E (!%C)
    """ |> Desel.Parser.parse
    data = Data.from_ast(ast)
    assert Data.elements_by(data, AST.set("B")) == {:error, data, """
    a cyclic graph appeared.
    %"C" -> %"D" -> %"E" -> %"C"
    """}
  end
end


