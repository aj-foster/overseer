defmodule FTC.Overseer.WLAN.Adapter do
  use GenServer
  require Logger

  alias FTC.Overseer.AdapterState
  alias FTC.Overseer.Executor

  defguard is_channel(x) when is_integer(x) and ((x > 0 and x < 12) or x > 35)

  ##########
  # Client #
  ##########

  @spec start_link(Keyword.t()) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(opts) do
    name = opts[:name] || raise ArgumentError, "Name required for WLAN adapter"

    case Executor.execute("iwconfig #{name}") do
      {:ok, _output} ->
        GenServer.start_link(__MODULE__, opts)

      {:error, _output, _code} ->
        message = "Could not configure WLAN adapter #{name}"
        Logger.error(message)
        {:error, message}
    end
  end

  @spec set_team(pid(), pos_integer()) :: :ok
  def set_team(adapter, team) do
    GenServer.cast(adapter, {:team, team})
  end

  ##########
  # Server #
  ##########

  @spec init(Keyword.t()) :: {:ok, AdapterState.t()}
  def init(opts) do
    {:ok, %AdapterState{name: opts[:name], channel: nil, active: false}}
  end

  def handle_call(:scan, _from, state) do
    Map.fetch!(state, :name)
    |> scan_command()
    |> Executor.execute()
    |> IO.inspect()

    {:reply, nil, state}
  end

  def handle_cast({:team, team}, state) do
    {:noreply, %{state | team: team}}
  end

  def handle_cast({:channel, channel}, state) when is_channel(channel) do
    Executor.execute("iwconfig #{state.name} #{channel}")
    {:noreply, %{state | channel: channel}}
  end

  ###########
  # Helpers #
  ###########

  defp scan_command(adapter) do
    """
    iwlist #{adapter} scan \
    | grep -E 'Address:|ESSID:|Channel:|Signal level=' \
    | sed -e 's/^.*Address: //' \
          -e 's/^\s*ESSID://' \
          -e 's/^\s*Channel://' \
          -e 's/.*Signal level=\(.*\) dBm\s*/\1/' \
    | awk '{ORS = (NR % 4 == 0)? "\n" : " | "; print}' \
    | grep 'DIRECT'
    """
  end
end
