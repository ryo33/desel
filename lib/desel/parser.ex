defmodule Desel.Parser do
  use Parselix
  use Parselix.Basic

  alias Desel.AST

  @whitespace_characters " " <> "　" <> "\t"
  @newline_characters "\n"

  def not_token, do: [wss, char("!"), wss] |> sequence |> compress
  def minus_token, do: [wss, char("-"), wss] |> sequence |> compress
  def and_token, do: [wss, char("&"), wss] |> sequence |> compress
  def prefix_of_set, do: char("%")
  def prefix_of_element, do: char("@")
  def prefix_of_inline_comment, do: char("#")
  def prefix_of_comment, do: not_char("%@")
  def ws, do: char(@whitespace_characters)
  def not_ws, do: not_char(@whitespace_characters)
  def wss, do: ws |> many |> compress
  def not_wss, do: not_ws |> many |> compress
  def wss1, do: ws |> many_1 |> compress
  def not_wss1, do: not_ws |> many_1 |> compress
  def option_not_wss, do: not_wss |> option
  def option_not_wss1, do: not_wss1 |> option
  def newline, do: char(@newline_characters)
  def not_newline, do: not_char(@newline_characters)
  def wss_newline, do: [wss, newline] |> sequence
  def label_character, do: not_char(~s/!-&%@()#"'/ <> @whitespace_characters)
  def label_characters, do: label_character |> many |> compress
  def utf_characters, do: not_newline |> many |> compress

  def label, do: [label_characters, wrapped_label] |> choice
  def wrapped_label do
    [[char(~s(")), label_characters, char(~s("))] |> sequence,
     [char(~s(")), label_characters, char(~s("))] |> sequence]
    |> choice
  end
  def homonymous_set do
    [wss, prefix_of_set, ws]
    |> sequence |> (fn p -> map({p, fn _ -> "%" end}) end).()
    |> option
  end
  def homonymous_element do
    [wss, prefix_of_element, ws]
    |> sequence |> (fn p -> map({p, fn _ -> "@" end}) end).()
    |> option
  end
  def set(prefix \\ false) do
    if prefix do
      [prefix_of_set, label]
    else
      [prefix_of_set |> option, label]
    end
    |> sequence
    |> clean
    |> (fn p -> map({p, fn
      [prefix, label] -> AST.set(prefix <> label, label)
      [label] -> AST.set(label, label)
    end}) end).()
  end
  def element(prefix \\ false) do
    if prefix do
      [prefix_of_element, label]
    else
      [prefix_of_element |> option, label]
    end
    |> sequence
    |> clean
    |> (fn p -> map({p, fn
      [prefix, label] -> AST.element(prefix <> label, label)
      [label] -> AST.element(label, label)
    end}) end).()
  end
  def opt_not(p) do
    [not_token |> option, p]
    |> sequence
    |> clean
    |> (fn p -> map({p, fn
      [token, target] -> AST.not_node(token, target)
      [target] -> target
    end}) end).()
  end
  def inline_comment, do: [wss, prefix_of_inline_comment, utf_characters, newline] |> sequence
  def comment, do: [prefix_of_comment, utf_characters, newline] |> sequence

  def statements, do: statement |> many
  def statement do
    [definition_of_set,
     definition_of_element,
     definition_of_sets,
     definition_of_elements,
     comment] |> choice
  end

  def set_item(prefix \\ false) do
    [[opt_not(element(prefix)), homonymous_set] |> sequence,
     opt_not(expression)]
    |> choice
  end

  def element_item(prefix \\ false) do
    opt_not(set(true))
  end

  def definition_of_set do
    [set(true),
     homonymous_element,
     option(set_item),
     [wss1, set_item] |> sequence |> many,
     inline_comment,
     [comment, [prefix_of_set, [wss1, set_item] |> sequence |> many, inline_comment] |> sequence]
     |> choice]
    |> sequence
  end

  def definition_of_element do
    [element(true),
     homonymous_set,
     option(set),
     [wss1, element_item] |> sequence |> many,
     inline_comment,
     [comment, [prefix_of_element, [wss1, element_item] |> sequence |> many, inline_comment] |> sequence]
     |> choice]
    |> sequence
  end

  def definition_of_sets do
    [times({prefix_of_set, 2}),
     [wss1, set, homonymous_element, option(set_item(true)), [wss1, set_item(true)] |> sequence |> many]
     |> sequence |> many,
     inline_comment]
    |> sequence
  end

  def definition_of_elements do
    [times({prefix_of_element, 2}),
     [wss1, element, homonymous_set, option(element_item(true)), [wss1, element_item(true)] |> sequence |> many]
     |> sequence |> many,
     inline_comment]
    |> sequence
  end

  def expression do
    [wrapped_expression,
     [expression_a, [choice([minus_token, wss1]), expression_a] |> sequence |> many]
     |> sequence]
    |> choice
  end

  def expression_a do
    [wrapped_expression,
     [expression_b, [and_token, expression_b] |> sequence |> many]
     |> sequence]
    |> choice
  end

  def expression_b do
    [wrapped_expression, opt_not(set(true))]
    |> choice
  end

  def wrapped_expression do
    [char("("), wss, expression, wss, char(")")]
    |> sequence
  end
end
