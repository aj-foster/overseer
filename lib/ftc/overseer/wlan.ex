defmodule FTC.Overseer.WLAN do
  use Supervisor
  require Logger

  alias FTC.Overseer.WLAN.Manager
  alias FTC.Overseer.WLAN.Supervisor, as: AdapterSupervisor
  alias FTC.Overseer.WLAN.Adapter

  @spec observe([pos_integer]) :: :ok
  def observe(teams) do
    adapters =
      DynamicSupervisor.which_children(AdapterSupervisor)
      |> Enum.map(fn {_id, pid, _type, _modules} -> pid end)

    if length(teams) > length(adapters) do
      missing_teams =
        Enum.slice(teams, length(adapters)..length(teams))
        |> Enum.join(", ")

      Logger.warn("Not enough WLAN adapters; dropping #{missing_teams}")
    end

    Enum.zip(adapters, teams)
    |> Enum.each(fn {adapter, team} ->
      Adapter.observe(adapter, team, temp: teams -- [team])
    end)

    :ok
  end

  def stop_all() do
    DynamicSupervisor.which_children(AdapterSupervisor)
    |> Enum.map(fn {_id, pid, _type, _modules} -> Adapter.stop(pid) end)

    :ok
  end

  @doc false
  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, any}
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  @impl true
  def init(_opts) do
    children = [
      AdapterSupervisor,
      Manager
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
