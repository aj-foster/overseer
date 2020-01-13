use Mix.Config

config :overseer,
  scoring_host: nil,
  scoring_event: nil

config :overseer, FTC.Display.Endpoint,
  server: true,
  http: [:inet6, port: 4000],
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
