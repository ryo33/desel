defmodule Desel.Mixfile do
  use Mix.Project

  def project do
    [app: :desel,
     version: "0.1.0",
     elixir: "~> 1.3",
     escript: escript,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  def escript do
    [main_module: Desel.CLI]
  end

  defp deps do
    [{:parselix, "~> 0.5.0"}]
  end
end
