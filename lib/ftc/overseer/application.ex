defmodule FTC.Overseer.Application do
  @moduledoc false
  use Application

  @spec start(any, any) :: {:ok, pid} | {:error, any}
  def start(_type, _args) do
    children = [
      FTC.Overseer.Executor,
      FTC.Overseer.MatchManager,
      FTC.Overseer.Scorekeeper,
      FTC.Overseer.WLAN,
      FTC.Display.Endpoint
    ]

    opts = [strategy: :one_for_one, name: FTC.Overseer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc false
  def config_change(changed, _new, removed) do
    FTC.Display.Endpoint.config_change(changed, removed)
    :ok
  end
end
