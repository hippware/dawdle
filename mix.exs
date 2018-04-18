defmodule Dawdle.MixProject do
  use Mix.Project

  def project do
    [
      app: :dawdle,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:credo, "~> 0.6", only: [:dev, :test], runtime: false},
      {:confex, "~> 3.3"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sqs, "~> 2.0"},
      {:hackney, "~> 1.7"},
      {:poison, "~> 3.1"},
      {:sweet_xml, "~> 0.6"}
    ]
  end
end
