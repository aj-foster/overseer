defmodule FTC.Overseer.MixProject do
  use Mix.Project

  def project do
    [
      app: :overseer,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {FTC.Overseer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Requests to scoring system
      {:httpoison, "~> 1.6"},
      {:websockex, "~> 0.4.2"},
      {:jason, "~> 1.1"},

      # Logging
      {:logger_file_backend, "~> 0.0.11"}
    ]
  end
end
