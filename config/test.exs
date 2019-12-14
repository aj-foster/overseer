use Mix.Config

config :overseer, FTC.Overseer.Scorekeeper.MockServer, server: true

config :overseer, FTC.Display.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
