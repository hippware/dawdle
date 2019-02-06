defmodule Dawdle.MixProject do
  use Mix.Project

  def project do
    [
      app: :dawdle,
      version: "0.4.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/hippware/dawdle"
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:confex, "~> 3.4"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sqs, "~> 2.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:hackney, "~> 1.7"},
      {:poison, "~> 3.0 or ~> 4.0"},
      {:sweet_xml, "~> 0.6"}
    ]
  end

  defp description do
    """
    Dawdle weaponizes Amazon SQS for use in your Elixir applications. Use it
    when you want to handle something later, or, better yet, when you want
    someone else to handle it.
    """
  end

  defp package do
    [
      maintainers: ["Bernard Duggan", "Phil Toland"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/hippware/dawdle"}
    ]
  end
end
