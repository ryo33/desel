defmodule Desel.AST do
  defmodule Set do
    defstruct label: nil
  end
  defmodule Element do
    defstruct label: nil
  end
  defmodule Expression do
    defstruct operator: nil, operand: nil
  end
  defmodule SetDefinition do
    defstruct set: nil, items: []
  end
  defmodule ElementDefinition do
    defstruct element: nil, items: []
  end
  defmodule SetsDefinition do
    defstruct sets: []
  end
  defmodule ElementsDefinition do
    defstruct elements: []
  end
  defmodule WithHomonymous do
    defstruct target: nil
  end
  @operators [:not, :and, :or, :minus]

  def set(label) do
    %__MODULE__.Set{
      label: label
    }
  end

  def element(label) do
    %__MODULE__.Element{
      label: label
    }
  end

  def expression(operator, operand) do
    %__MODULE__.Expression{
      operator: operator,
      operand: operand
    }
  end

  def set_definition(set, items) do
    %__MODULE__.SetDefinition{
      set: set,
      items: items
    }
  end

  def element_definition(element, items) do
    %__MODULE__.ElementDefinition{
      element: element,
      items: items
    }
  end

  def set_definition(sets) do
    %__MODULE__.SetsDefinition{
      sets: sets
    }
  end

  def elements_definition(elements) do
    %__MODULE__.ElementsDefinition{
      elements: elements
    }
  end

  def with_homonymous(target) do
    %__MODULE__.WithHomonymous{
      target: target
    }
  end
end
