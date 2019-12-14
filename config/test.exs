use Mix.Config

config :overseer, FTC.Display.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
