defmodule Dawdle.MixProject do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :dawdle,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
      source_url: "https://github.com/hippware/dawdle",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Dawdle.Application, []}
    ]
  end

  defp deps do
    [
      {:confex, "~> 3.4"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sqs, "~> 2.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:excoveralls, "~> 0.10", only: :test},
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

  defp docs do
    [
      source_ref: "v#\{@version\}",
      main: "readme",
      extras: ["README.md"],
      groups_for_modules: [
        "API": [
          Dawdle,
          Dawdle.Client,
          Dawdle.Handler
        ],
        "Backend Implementation": [
          Dawdle.Backend,
          Dawdle.Backend.Local,
          Dawdle.Backend.SQS,
          Dawdle.MessageEncoder,
          Dawdle.MessageEncoder.Term
        ]
      ]
    ]
  end
end
