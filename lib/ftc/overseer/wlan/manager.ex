defmodule FTC.Overseer.WLAN.Manager do
  use GenServer
  require Logger

  alias FTC.Overseer.Event
  alias FTC.Overseer.Executor
  alias FTC.Overseer.WLAN.Adapter
  alias FTC.Overseer.WLAN.Supervisor, as: AdapterSupervisor

  @typep state :: [String.t()]

  ##########
  # Client #
  ##########

  @spec start_link(any) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(_opts \\ []) do
    adapters = list_adapters()

    case length(adapters) do
      0 ->
        Logger.warn("No WLAN adapters found")

      1 ->
        Logger.info("Found 1 WLAN adapter: #{Enum.at(adapters, 0)}")

      num ->
        Logger.info("Found #{num} WLAN adapters: #{Enum.join(adapters, ", ")}")
    end

    GenServer.start_link(__MODULE__, adapters, name: __MODULE__)
  end

  ##########
  # Server #
  ##########

  @spec init([String.t()]) :: {:ok, state}
  def init(adapters) do
    Enum.each(adapters, fn adapter ->
      AdapterSupervisor.start_adapter(adapter)
    end)

    :ok = Event.subscribe("match")
    {:ok, adapters}
  end

  def handle_info({:populated, _match_name, teams}, state) do
    observe(teams)
    {:noreply, state}
  end

  def handle_info({:ended, _match_name}, state) do
    stop_all()
    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  ###########
  # Helpers #
  ###########

  @get_adapters "iwconfig 2>/dev/null | grep 'IEEE 802.11' | cut -d' ' -f 1 | grep wlan"

  defp list_adapters() do
    case Executor.execute(@get_adapters) do
      {:ok, output} ->
        output
        |> String.trim()
        |> String.split(~r/\s/, trim: true)
        |> Enum.sort()

      _ ->
        []
    end
  end

  # Begin observing the given teams.
  #
  @spec observe([pos_integer]) :: :ok
  defp observe(teams) do
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

  # Stop observing all teams.
  @spec stop_all() :: :ok
  defp stop_all() do
    DynamicSupervisor.which_children(AdapterSupervisor)
    |> Enum.map(fn {_id, pid, _type, _modules} -> Adapter.stop(pid) end)

    :ok
  end
end
