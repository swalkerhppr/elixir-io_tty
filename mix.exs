defmodule IOTty.Mixfile do
  use Mix.Project

  def project do
    [app: :io_tty,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test],
     deps: deps()]
  end

  def application do
    []
  end

  defp deps do
    [{:excoveralls, "~> 0.7", only: :test}]
  end
end
