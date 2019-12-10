use Mix.Config

config :overseer,
  scoring_host: "http://localhost:8382",
  scoring_event: "test_01"

config :overseer, FTC.Display.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HRSGLDwsuQTLGdqZp0za5VT4roFjXDX8+n6jjnKODtrbvgJXcpXpMIJSSJJ+dtJH",
  render_errors: [view: FTC.Display.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FTC.Display.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "HRSGLDwsuQTLGdqZp0za5VT4roFjXDX8+n6jjnKODtrbvgJXcpXpMIJSSJJ+dtJH"
  ]

config :logger, level: :debug

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
