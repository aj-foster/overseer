import Config

config :overseer,
  scoring_host: System.get_env("SCORING_HOST", "http://localhost:8382"),
  scoring_event: System.get_env("SCORING_EVENT", "test_01")
