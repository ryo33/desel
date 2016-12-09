defmodule Desel.Data do
  defstruct sets: %{}, elements: MapSet.new(), set_caches: %{}

  alias Desel.AST

  def from_ast(ast) do
    from_ast(%{sets: %{}, elements: MapSet.new()}, ast)
  end

  defp from_ast(data, []), do: data
  defp from_ast(data, [head | tail]) do
    data = case head do
      %AST.SetDefinition{set: set, items: items} ->
        add_set(data, set, items)
      %AST.ElementDefinition{element: element, items: items} ->
        add_element_definition(data, element, items)
      %AST.SetsDefinition{sets: sets} ->
        Enum.reduce(sets, data, &add_set(&2, &1.set, &1.items))
      %AST.ElementsDefinition{elements: elements} ->
        Enum.reduce(elements, data, &add_element_definition(&2, &1.element, &1.items))
    end
    |> from_ast(tail)
    %__MODULE__{
      sets: data.sets,
      elements: data.elements
    }
  end

  defp add_set(data, %AST.Set{label: set}, items) do
    if Map.has_key?(data.sets, set) do
      update_in(data, [:sets, set], &(&1 ++ items))
    else
      put_in(data, [:sets, set], items)
    end
    |> collect_elements_from_items(items)
  end

  defp collect_elements_from_items(data, []), do: data
  defp collect_elements_from_items(data, [head | tail]) do
    case head do
      %AST.Element{} = element ->
        add_element(data, element)
        |> collect_elements_from_items(tail)
      %AST.Expression{operator: :not, operand: %AST.Element{} = element} ->
        add_element(data, element)
        |> collect_elements_from_items(tail)
      _ -> collect_elements_from_items(data, tail)
    end
  end

  defp add_element(data, %AST.Element{label: element}) do
    Map.update!(data, :elements, fn mapset -> MapSet.put(mapset, element) end)
  end

  defp add_element_definition(data, element, items) do
    Enum.reduce(items, data, fn set, data ->
      case set do
        %AST.Expression{operator: :not, operand: set} ->
          add_set(data, set, [AST.expression(:not, element)])
        set ->
          add_set(data, set, [element])
      end
    end)
    |> add_element(element)
  end

  def sets(data) do
    data.sets
    |> Map.keys()
    |> MapSet.new()
  end

  def elements(data), do: data.elements

  def elements_by(data, ast) do
    elements_by(data, ast, [])
  end

  defp elements_by(data, ast, visited)

  # By an element
  defp elements_by(data, %AST.Element{label: element}, _visited) do
    elements = MapSet.new([element])
    {:ok, data, elements}
  end

  # By a set
  defp elements_by(data, %AST.Set{label: set}, visited) do
    if set in visited do
      cyclic = Enum.reverse(visited)
               |> Enum.drop_while(&(&1 != set))
               |> Enum.map(&(~s(%"#{&1}")))
               |> Enum.join(" -> ")
      message = """
      a cyclic graph appeared.
      #{cyclic} -> %"#{set}"
      """
      {:error, data, message}
    else
      case Map.fetch(data.set_caches, set) do
        {:ok, elements} ->
          {:ok, data, elements}
        :error -> case Map.fetch(data.sets, set) do
          {:ok, items} ->
            visited = [set | visited]
            result = elements_by_set(data, items, visited, MapSet.new())
            with {:ok, data, elements, minus} <- result do
              elements = MapSet.difference(elements, minus)
              data = %__MODULE__{data | set_caches: Map.put(data.set_caches, set, elements)}
              {:ok, data, elements}
            end
          :error ->
            message = """
            %"#{set}" does not exist.
            """
            {:error, data, message}
          end
      end
    end
  end

  # By an expression
  defp elements_by(data, %AST.Expression{operator: :not, operand: ast}, visited) do
    with {:ok, data, evaluated} <- elements_by(data, ast, visited) do
      elements = MapSet.difference(data.elements, evaluated)
      {:ok, data, elements}
    end
  end

  defp elements_by(data, %AST.Expression{operator: operator, operand: operands}, visited) do
    with {:ok, data, elements} <- elements_by_expression(data, operator, operands, visited) do
      {:ok, data, elements}
    end
  end

  defp elements_by_set(data, [], _, minus), do: {:ok, data, MapSet.new(), minus}
  defp elements_by_set(data, [head | tail], visited, minus) do
    case head do
      %AST.Expression{operator: :not, operand: %AST.Element{label: element}} ->
        minus = MapSet.put(minus, element)
        elements_by_set(data, tail, visited, minus)
      ast ->
        with {:ok, data, head} <- elements_by(data, ast, visited),
             {:ok, data, tail, minus} <- elements_by_set(data, tail, visited, minus) do
          elements = MapSet.union(head, tail)
          {:ok, data, elements, minus}
        end
    end
  end

  defp elements_by_expression(data, _, [head], visited), do: elements_by(data, head, visited)
  defp elements_by_expression(data, operator, [last | left], visited) do
    with {:ok, data, left} <- elements_by_expression(data, operator, left, visited),
         {:ok, data, last} <- elements_by(data, last, visited) do
      elements = case operator do
        :or -> MapSet.union(left, last)
        :and -> MapSet.intersection(left, last)
        :minus -> MapSet.difference(left, last)
      end
      {:ok, data, elements}
    end
  end
end
