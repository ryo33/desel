defmodule DeselTest.Parser do
  use ExUnit.Case
  doctest Desel.Parser

  use Parselix
  import Desel.Parser
  alias Desel.AST

  defp assert_parse(parser, target, ast, remainder \\ "") do
    result = parser |> parse(target)
    pos = get_position(position, target, String.length(target) - String.length(remainder))
    assert result == {:ok, ast, remainder, pos}
  end

  test "element and set" do
    target = "@label"
    ast = AST.element("label")
    assert_parse(element(true), target, ast)

    target = "label"
    ast = AST.set("label")
    assert_parse(set, target, ast)
  end

  test "opt_not" do
    target = "! %label"
    parser = set(true) |> opt_not
    ast = AST.expression(:not, AST.set("label"))
    assert_parse(parser, target, ast)

    target = "!label"
    parser = element |> opt_not
    ast = AST.expression(:not, AST.element("label"))
    assert_parse(parser, target, ast)
  end

  test "expression" do
    target = "%A"
    ast = AST.set("A")
    assert_parse(expression, target, ast)

    target_or = "(%A !%B %C)"
    ast_or = AST.expression(:or, [AST.set("C"), AST.expression(:not, AST.set("B")), AST.set("A")])
    assert_parse(expression, target_or, ast_or)

    target_minus = "! %A - %B-!%C"
    ast_minus = AST.expression(:minus, [AST.expression(:not, AST.set("C")), AST.set("B"), AST.expression(:not, AST.set("A"))])
    assert_parse(expression, target_minus, ast_minus)

    target_and = "! %A & %B&!%C"
    ast_and = AST.expression(:and, [AST.expression(:not, AST.set("C")), AST.set("B"), AST.expression(:not, AST.set("A"))])
    assert_parse(expression, target_and, ast_and)

    target = "(#{target_or}) & %E"
    ast = AST.expression(:and, [AST.set("E"), ast_or])
    assert_parse(expression, target, ast)

    target = "#{target_and} - %D & (#{target_minus}) - (#{target_or}) & %E"
    ast = AST.expression(:minus, [
      AST.expression(:and, [AST.set("E"), ast_or]),
      AST.expression(:and, [ast_minus, AST.set("D")]),
      ast_and
    ])
    assert_parse(expression, target, ast)
  end

  test "definition_of_set" do
    target = """
    %'A' element1 "This is the element2." @"Specifies prefix" ! "This is not contained."

    %
    %    %B !%C - %D %E   # comment

    This is a comment.

    % element5 %
    %

    """
    items = [
      AST.element("element1"),
      AST.element("This is the element2."),
      AST.element("Specifies prefix"),
      AST.expression(:not, AST.element("This is not contained.")),
      AST.set("B"),
      AST.expression(:minus, [AST.set("D"), AST.expression(:not, AST.set("C"))]),
      AST.set("E"),
      AST.with_homonymous(AST.element("element5"))
    ]
    ast = AST.set_definition(AST.set("A"), items)
    assert_parse(definition_of_set, target, ast)

    target = """
    %A@
    """
    ast = AST.set_definition(AST.set("A"), [AST.element("A")])
    assert_parse(definition_of_set, target, ast)
  end

  test "definition_of_element" do
    target = """
    @a A %B

    @  ! C !%D # comment
    @

    """
    items = [
      AST.set("A"),
      AST.set("B"),
      AST.expression(:not, AST.set("C")),
      AST.expression(:not, AST.set("D")),
    ]
    ast = AST.element_definition(AST.element("a"), items)
    assert_parse(definition_of_element, target, ast)

    target = """
    @A%
    """
    ast = AST.element_definition(AST.element("A"), [AST.set("A")])
    assert_parse(definition_of_element, target, ast)
  end

  test "definition_of_sets" do
    target = """
    %% %A @a% b c (%B) %B (%C - %D & %E) %C !(%D - %E)
    """
    a = [
      AST.with_homonymous(AST.element("a")),
      AST.element("b"),
      AST.element("c"),
      AST.set("B")
    ]
    b = [
      AST.expression(:minus, [
        AST.expression(:and, [
          AST.set("E"), AST.set("D")
        ]), AST.set("C")
      ])
    ]
    c = [
      AST.expression(:not, AST.expression(:minus, [
        AST.set("E"), AST.set("D")
      ]))
    ]
    ast = [
      AST.set_definition(AST.set("A"), a),
      AST.set_definition(AST.set("B"), b),
      AST.set_definition(AST.set("C"), c),
    ]
    assert_parse(definition_of_sets, target, ast)
  end

  test "definition_of_elements" do
    target = """
    @@ @a %A %B @b B C @c % !D
    """
    a = [
      AST.set("A"),
      AST.set("B")
    ]
    b = [
      AST.set("B"),
      AST.set("C")
    ]
    c = [
      AST.set("c"),
      AST.expression(:not, AST.set("D"))
    ]
    ast = [
      AST.element_definition(AST.element("a"), a),
      AST.element_definition(AST.element("b"), b),
      AST.element_definition(AST.element("c"), c),
    ]
    assert_parse(definition_of_elements, target, ast)
  end

  test "desel" do
    target = """
    %A a b c
    comment
    @c B C # comment
    @@ @d %B @e %B %C
    %B %A
    %C %A & %C %B x y z
    """
    ast = [
      AST.set_definition(AST.set("A"), [AST.element("a"), AST.element("b"), AST.element("c")]),
      AST.element_definition(AST.element("c"), [AST.set("B"), AST.set("C")]),
      AST.element_definition(AST.element("d"), [AST.set("B")]),
      AST.element_definition(AST.element("e"), [AST.set("B"), AST.set("C")]),
      AST.set_definition(AST.set("B"), [AST.set("A")]),
      AST.set_definition(AST.set("C"), [
        AST.expression(:and, [AST.set("C"), AST.set("A")]),
        AST.set("B"),
        AST.element("x"),
        AST.element("y"),
        AST.element("z"),
      ]),
    ]
    assert_parse(desel, target, ast)
    assert parse(target) |> elem(1) == ast
  end
end
