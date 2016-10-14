defmodule Desel.AST do
  defmodule Set do
    defstruct token: nil, label: nil
  end
  defmodule Element do
    defstruct token: nil, label: nil
  end
  defmodule Not do
    defstruct token: nil, target: nil
  end

  def set(token, label) do
    %__MODULE__.Set{
      token: token,
      label: label
    }
  end

  def element(token, label) do
    %__MODULE__.Element{
      token: token,
      label: label
    }
  end

  def not_node(token, target) do
    %__MODULE__.Not{
      token: token,
      target: target
    }
  end
end
