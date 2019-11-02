defmodule FTC.Overseer.Application do
  @moduledoc false

  use Application

  @spec start(any, any) :: {:ok, pid} | {:error, any}
  def start(_type, _args) do
    children = [
      FTC.Overseer.MatchManager,
      FTC.Overseer.Scorekeeper.Websocket,
      FTC.Overseer.WLAN
    ]

    opts = [strategy: :one_for_one, name: FTC.Overseer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
