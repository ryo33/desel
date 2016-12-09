defmodule Desel.CLI do
  @struct [
    help: :boolean
  ]

  @help """
  Usage:
    desel [file] [expression ...]  List elements by expressions
    desel - [expression ...]       Read text from stdin
  """

  def main(args \\ []) do
    args
    |> parse_args
    |> response
  end

  defp parse_args(args) do
    args
    |> OptionParser.parse(struct: @struct)
  end

  defp response({_, _, [{illeagal, _}|_]}) do
    panic """
    illeagal option -- #{to_string(illeagal)}
    """
  end

  defp response({opts, ["-" | expression], _}) do
    lines = IO.stream(:stdio, :line) |> Enum.to_list()
    desel = Enum.join(lines)
    lines = Enum.map(lines, &String.trim_trailing(&1, "\n"))
    process(opts, desel, lines, expression)
  end

  defp response({opts, [file | expression], _}) when length(expression) != 0 do
    case File.read(file) do
      {:ok, desel} ->
        lines = String.split(desel, "\n")
        process(opts, desel, lines, expression)
      {:error, reason} ->
        panic """
        failed to read the file: #{to_string(reason)}
        """
    end
  end

  defp response({{:help, true}, _, _}) do
    IO.write(@help)
  end

  defp response({_, _, _}) do
    panic @help
  end

  defp process(_opts, desel, lines, expression) do
    alias Desel.Parser
    alias Desel.Data
    ast = case Parser.parse(desel) do
      {:ok, ast, _, _} -> ast
      {:error, message, position} ->
        line = Enum.at(lines, position.vertical)
        line_num = "#{to_string(position.vertical)}: "
        spaces = position.horizontal + String.length(line_num)
        spaces = String.duplicate(" ", spaces)
        panic """
        failed to parse the input

        #{line_num}#{line}
        #{spaces}^ #{message}
        """
    end
    data = Data.from_ast(ast)
    expression = Enum.join(expression, " ")
    expression = case Parser.parse_expression("(#{expression})") do
      {:ok, ast, _, _} -> ast
      {:error, message, position} ->
        spaces = String.duplicate(" ", position.horizontal - 1) # "("
        panic """
        failed to parse the given expression

        #{expression}
        #{spaces}^ #{message}
        """
    end
    {data, elements} = case Data.elements_by(data, expression) do
      {:ok, data, elements} -> {data, elements}
      {:error, data, message} ->
        panic """
        #{message}
        """
    end
    Enum.each(elements, &IO.puts(&1))
  end

  defp panic(message) do
    IO.write(:stderr, "desel: #{message}")
    System.halt(1)
  end
end
