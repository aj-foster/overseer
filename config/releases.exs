import Config

config :overseer,
  scoring_host: System.get_env("SCORING_HOST", "http://localhost:8382"),
  scoring_event: System.get_env("SCORING_EVENT", "test_01")

config :logger,
  backends: [:console, {LoggerFileBackend, :debug_log}]

config :logger, :debug_log,
  path: "log/debug.log",
  level: :debug
