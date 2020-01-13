use Mix.Config

# Overseer

config :overseer,
  scoring_host: "http://localhost:8382",
  scoring_event: "test_01",
  target: Mix.target()

config :overseer, FTC.Overseer.Scorekeeper.MockServer,
  server: false,
  http: [:inet6, port: 8382],
  url: [host: "localhost", port: 8382],
  secret_key_base: "HRSGLDwsuQTLGdqZp0za5VT4roFjXDX8+n6jjnKODtrbvgJXcpXpMIJSSJJ+dtJH",
  render_errors: [view: FTC.Display.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FTC.Overseer.PubSub, adapter: Phoenix.PubSub.PG2]

config :overseer, FTC.Display.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HRSGLDwsuQTLGdqZp0za5VT4roFjXDX8+n6jjnKODtrbvgJXcpXpMIJSSJJ+dtJH",
  render_errors: [view: FTC.Display.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FTC.Display.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "HRSGLDwsuQTLGdqZp0za5VT4roFjXDX8+n6jjnKODtrbvgJXcpXpMIJSSJJ+dtJH"
  ]

# Logger

config :logger, level: :debug

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Phoenix

config :phoenix, :json_library, Jason

# Nerves

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]

# Environment-specific configuration

import_config "#{Mix.env()}.exs"

if Mix.target() != :host do
  import_config "target.exs"
end
