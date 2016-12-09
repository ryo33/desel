defmodule Desel.Parser do
  import Parselix
  import Parselix.Basic

  alias Desel.AST

  @whitespace_characters " " <> "　" <> "\t"
  @newline_characters "\n"

  def parse(target) do
    desel |> parse(target, position)
  end

  def parse_expression(target) do
    expression |> parse(target, position)
  end

  parser :begin_token, do: [wss, char("("), wss] |> sequence |> concat
  parser :end_token, do: [wss, char(")")] |> sequence |> concat
  parser :not_token, do: [wss, char("!"), wss] |> sequence |> concat
  parser :minus_token, do: [wss, char("-"), wss] |> sequence |> concat
  parser :and_token, do: [wss, char("&"), wss] |> sequence |> concat
  parser :prefix_of_set, do: char("%")
  parser :prefix_of_element, do: char("@")
  parser :prefix_of_inline_comment, do: char("#")
  parser :prefix_of_comment, do: not_char("%@" <> @newline_characters)
  parser :ws, do: char(@whitespace_characters)
  parser :not_ws, do: not_char(@whitespace_characters)
  parser :wss, do: ws |> many |> concat
  parser :not_wss, do: not_ws |> many |> concat
  parser :wss1, do: ws |> many_1 |> concat
  parser :not_wss1, do: not_ws |> many_1 |> concat
  parser :option_not_wss, do: not_wss |> option
  parser :option_not_wss1, do: not_wss1 |> option
  parser :newline, do: char(@newline_characters)
  parser :not_newline, do: not_char(@newline_characters)
  parser :wss_newline, do: [wss, newline] |> sequence
  parser :label_character, do: not_char(~s/!-&%@()#"'/ <> @whitespace_characters <> @newline_characters)
  parser :label_characters, do: label_character |> many_1 |> concat
  parser :utf_characters, do: not_newline |> many_1 |> concat
  parser :double_quote_characters, do: not_char(~s(") <> @newline_characters) |> many_1 |> concat
  parser :single_quote_characters, do: not_char(~s(') <> @newline_characters) |> many_1 |> concat
  parser :label, do: [label_characters, wrapped_label] |> choice

  parser :wrapped_label do
    [[char(~s(")), double_quote_characters, char(~s("))] |> sequence,
     [char(~s(')), single_quote_characters, char(~s('))] |> sequence]
    |> choice
    |> pick(1)
  end

  parser :homonymous_set do
    [wss, prefix_of_set, [ws, newline] |> choice |> ignore]
    |> sequence
    |> map(fn _ -> true end)
    |> default(false)
  end

  parser :homonymous_element do
    [wss, prefix_of_element, [ws, newline] |> choice |> ignore]
    |> sequence
    |> map(fn _ -> true end)
    |> default(false)
  end

  def set(prefix \\ false) do
    parser_body do
      if prefix do
        [prefix_of_set, label]
      else
        [prefix_of_set |> option, label]
      end
      |> sequence
      |> clean
      |> map(fn
        [_prefix, label] -> AST.set(label)
        [label] -> AST.set(label)
      end)
    end
  end

  def element(prefix \\ false) do
    parser_body do
      if prefix do
        [prefix_of_element, label]
      else
        [prefix_of_element |> option, label]
      end
      |> sequence
      |> clean
      |> map(fn
        [_prefix, label] -> AST.element(label)
        [label] -> AST.element(label)
      end)
    end
  end

  parser :opt_not, [p] do
    [not_token |> option, dump(wss), p]
    |> sequence
    |> clean
    |> map(fn
      [_token, target] -> AST.expression(:not, target)
      [target] -> target
    end)
  end

  parser :inline_comment do
    [wss,
     [prefix_of_inline_comment, utf_characters] |> sequence |> option,
     newline]
    |> sequence
    |> dump
  end

  parser :comment do
    [wss_newline,
     [prefix_of_comment, option(utf_characters), wss_newline] |> sequence]
    |> choice
    |> dump
  end

  parser :desel do
    fn target, position ->
      statements = statement
                   |> many
                   |> flat_once
      case statements.(target, position) do
        {:ok, _, "", _} = result ->
          result
        {:ok, _, remainder, position} ->
          statement().(remainder, position)
      end
    end
  end

  parser :statement do
    [definition_of_set,
     definition_of_element,
     definition_of_sets,
     definition_of_elements,
     dump(comment)]
    |> choice
  end

  parser :with_homonymous, [target, homonymous] do
    [target, homonymous]
    |> sequence
    |> map(fn [target, homonymous] ->
      if homonymous == true do
        AST.with_homonymous(target)
      else
        target
      end
    end)
  end

  def set_item(prefix \\ false, expression) do
    parser_body do
      [with_homonymous(opt_not(element(prefix)), homonymous_set),
       expression]
      |> choice
    end
  end

  def element_item(prefix \\ false) do
    parser_body do
      opt_not(set(prefix))
    end
  end

  parser :definition_of_set do
    items = [wss1, set_item(expression)] |> sequence |> pick(1) |> many
    [set(true),
     homonymous_element,
     items,
     dump(inline_comment),
     additional_definition(prefix_of_set, set_item(expression))]
    |> sequence
    |> clean
    |> map(fn [set, homonymous, items, lines] ->
      items = items ++ lines
      items = if homonymous, do: [AST.element(set.label) | items], else: items
      AST.set_definition(set, items)
    end)
  end

  parser :definition_of_element do
    [element(true),
     homonymous_set,
     [wss1, element_item] |> sequence |> pick(1) |> many,
     inline_comment,
     additional_definition(prefix_of_element, element_item)]
    |> sequence
    |> clean
    |> map(fn [element, homonymous, items, lines] ->
      items = items ++ lines
      items = if homonymous, do: [AST.set(element.label) | items], else: items
      AST.element_definition(element, items)
    end)
  end

  parser :additional_definition, [prefix, item] do
    line = [prefix, [wss1, item] |> sequence |> pick(1) |> many, inline_comment]
           |> sequence
           |> pick(1)
    [line, comment]
    |> choice
    |> many
    |> clean
    |> flat_once
  end

  parser :definition_of_sets do
    items = [wss1, set_item(opt_not(wrapped_expression))] |> sequence |> pick(1) |> many
    sets = [wss1, with_homonymous(set(true), homonymous_element), items]
           |> sequence
           |> map(fn [_, set, items] ->
             {set, items} = case set do
               %AST.WithHomonymous{target: set} ->
                 {set, [AST.element(set.label) | items]}
               _ -> {set, items}
             end
             AST.set_definition(set, items)
           end)
           |> many
    [times(prefix_of_set, 2),
     sets,
     inline_comment]
    |> sequence
    |> pick(1)
  end

  parser :definition_of_elements do
    items = [wss1, element_item] |> sequence |> pick(1) |> many
    elements = [wss1, with_homonymous(element(true), homonymous_set), items]
           |> sequence
           |> map(fn [_, element, items] ->
             {element, items} = case element do
               %AST.WithHomonymous{target: element} ->
                 {element, [AST.set(element.label) | items]}
               _ -> {element, items}
             end
             AST.element_definition(element, items)
           end)
           |> many
    [times(prefix_of_element, 2),
     elements,
     inline_comment]
    |> sequence
    |> pick(1)
  end

  parser :expression do
    expression_operator(:minus, minus_token, expression_and)
  end

  parser :expression_and do
    expression_operator(:and, and_token, expression3)
  end

  parser :expression3 do
    [opt_not(set(true)), opt_not(wrapped_expression)]
    |> choice
  end

  parser :wrapped_expression do
    [begin_token, wss, expression_or , wss, end_token]
    |> sequence
    |> pick(2)
  end

  parser :expression_or do
    expression_operator(:or, wss1, expression)
  end

  parser :expression_operator, [operator, operator_parser, operand] do
    right = [operator_parser, operand]
            |> sequence
            |> pick(1)
            |> many
    [operand, right]
    |> sequence
    |> map(fn [left, right] ->
      case right do
        [] -> left
        right -> AST.expression(operator, [left | right])
      end
    end)
  end
end
