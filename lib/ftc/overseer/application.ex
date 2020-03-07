defmodule FTC.Overseer.Application do
  @moduledoc false
  use Application

  @spec start(any, any) :: {:ok, pid} | {:error, any}
  def start(_type, opts) do
    children =
      [
        {Phoenix.PubSub.PG2, name: FTC.PubSub},
        FTC.Overseer.Executor,
        FTC.Overseer.MatchManager,
        FTC.Overseer.Scorekeeper,
        FTC.Overseer.WLAN,
        FTC.Display.Endpoint,
        FTC.Overseer.Scorekeeper.MockServer
      ] ++ console_children(opts[:console])

    opts = [strategy: :one_for_one, name: FTC.Overseer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp console_children(true), do: [FTC.Overseer.Console]
  defp console_children(_false), do: []

  @doc false
  def config_change(changed, _new, removed) do
    FTC.Display.Endpoint.config_change(changed, removed)
    :ok
  end
end
