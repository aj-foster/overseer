defmodule FTC.Overseer.MixProject do
  use Mix.Project

  @app :overseer
  @version "0.1.0"
  @target System.get_env("MIX_TARGET", "host")
  @all_targets [:nerves_system_overseer]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: [loadconfig: [&bootstrap/1]],
      archives: [nerves_bootstrap: "~> 1.6"],
      build_embedded: true,
      compilers: [:phoenix] ++ Mix.compilers(),
      deps: deps(),
      preferred_cli_target: [run: :host, test: :host],
      releases: [{@app, release()}],
      start_permanent: Mix.env() == :prod
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {FTC.Overseer.Application, []}
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Additional files to compile during testing.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Requests to scoring system
      {:httpoison, "~> 1.6"},
      {:websockex, "~> 0.4.2"},
      {:jason, "~> 1.1"},

      # Logging
      {:logger_file_backend, "~> 0.0.11"},

      # Retry and backoff logic
      {:retry, "~> 0.13"},

      # Web Display
      {:phoenix, "~> 1.4.9"},
      {:phoenix_pubsub, "~> 1.1"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.4"},
      {:floki, ">= 0.0.0", only: :test},
      {:plug_cowboy, "~> 2.0"},

      # Nerves (all targets)
      {:nerves, "~> 1.5.0", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.6"},
      {:toolshed, "~> 0.2"},
      {:nerves_runtime_shell, "~> 0.1.0"},

      # Nerves (all targets except :host)
      {:nerves_runtime, "~> 0.6", targets: @all_targets},
      {:nerves_init_gadget, "~> 0.4", targets: @all_targets}
    ] ++ system_deps(@target)
  end

  def system_deps("host"), do: []

  def system_deps(_target) do
    [
      {:nerves_system_overseer,
       git: "https://github.com/aj-foster/nerves_system_overseer.git",
       tag: "0.1.0",
       runtime: false,
       targets: :nerves_system_overseer,
       nerves: [compile: true]}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
