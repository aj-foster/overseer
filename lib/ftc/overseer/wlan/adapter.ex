defmodule FTC.Overseer.WLAN.Adapter do
  use GenServer
  require Logger

  alias FTC.Display.Status
  alias FTC.Overseer.AdapterState
  alias FTC.Overseer.Executor

  ##########
  # Client #
  ##########

  @doc """
  Initialize wireless adapter with the given interface name.

  ## Options

    * `:name`: (**required** string) Name of the interface, i.e. `"wlan0"`.
  """
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

  @doc """
  Begin observing the given `team` using the given `adapter`.
  """
  @spec observe(pid, pos_integer, Keyword.t()) :: :ok
  def observe(adapter, team, opts \\ []) do
    GenServer.cast(adapter, {:start, team, opts[:temp] || []})
  end

  @doc """
  Stop the given `adapter` from observing teams.
  """
  @spec stop(pid) :: :ok
  def stop(adapter) do
    GenServer.cast(adapter, :stop)
  end

  ##########
  # Server #
  ##########

  @doc false
  @spec init(Keyword.t()) :: {:ok, AdapterState.t()}
  def init(opts) do
    {:ok, %AdapterState{name: opts[:name], channel: nil, active_pid: nil}}
  end

  @doc false
  @spec handle_cast({:start, pos_integer, [pos_integer]} | :stop, AdapterState.t()) ::
          {:noreply, AdapterState.t()}
  def handle_cast({:start, team, _other_teams}, state) do
    Process.send(self(), :observe, [])
    {:noreply, %{state | team: team}}
  end

  def handle_cast(:stop, %{active_pid: pid} = state) when is_pid(pid) do
    Executor.stop(pid)
    {:noreply, %{state | team: nil, active_pid: nil, channel: nil, bssid: nil}}
  end

  def handle_cast(:stop, state) do
    {:noreply, %{state | team: nil, active_pid: nil, channel: nil, bssid: nil}}
  end

  @doc false
  @spec handle_info(:observe | :tshark, AdapterState.t()) :: {:noreply, AdapterState.t()}
  def handle_info(:observe, %{team: team} = state) when is_nil(team) do
    {:noreply, state}
  end

  def handle_info(:observe, %{name: name, team: team} = state) do
    do_scan(name)
    |> Enum.filter(fn %{"team" => team_number} -> team_number == team end)
    |> Enum.sort_by(fn %{"signal" => signal} -> signal end)
    |> List.last()
    |> case do
      %{"channel" => channel, "address" => address} ->
        Logger.debug("Team #{team} found on channel #{channel} (BSSID #{address})")
        Process.send(self(), :tshark, [])

        {:noreply, %{state | team: team, channel: channel, bssid: address}}

      _ ->
        Logger.warn("Team #{team} not found in scan")
        Process.send_after(self(), :observe, 1000)
        {:noreply, %{state | team: team}}
    end
  end

  def handle_info(:tshark, %{team: team, channel: channel, bssid: bssid} = state)
      when is_nil(team) or is_nil(channel) or is_nil(bssid) do
    {:noreply, state}
  end

  def handle_info(:tshark, %{name: name, team: team, channel: channel, bssid: bssid} = state) do
    case Executor.spawn("./bin/tshark #{name} #{channel} #{bssid}", team,
           on_output: &process_tshark_output/2
         ) do
      {:ok, pid} ->
        Logger.debug("Started tshark for team #{team}")
        Status.tracking_team(team)
        {:noreply, %{state | active_pid: pid}}

      {:error, reason} ->
        Logger.warn("Error while starting tshark: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  ###########
  # Helpers #
  ###########

  @scan_line ~r/^(?<address>([A-F0-9:])*) \| (?<channel>\d+) \| (?<signal>-?\d+) \| "(?<SSID>.*)"$/
  @valid_ssid ~r/DIRECT-[[:alnum:]]+-(?<team>\d+)-/i

  # Perform a scan for nearby WiFi-Direct networks.
  #
  @spec do_scan(String.t()) :: [map]
  defp do_scan(adapter_name) do
    case Executor.execute("./bin/scan \"#{adapter_name}\"") do
      {:ok, output} -> process_scan_output(output)
      {:error, _output, _code} -> []
    end
  end

  # Process network scan output into a list of maps.
  #
  @spec process_scan_output(String.t()) :: [map]
  defp process_scan_output(output) do
    String.split(output, "\n", trim: true)
    |> Stream.map(fn line -> Regex.named_captures(@scan_line, line) end)
    |> Stream.reject(&is_nil/1)
    |> Stream.map(fn %{"SSID" => ssid} = record ->
      with %{"team" => team_str} <- Regex.named_captures(@valid_ssid, ssid),
           {team, ""} <- Integer.parse(team_str) do
        Map.put(record, "team", team)
      else
        _ -> nil
      end
    end)
    |> Stream.reject(&is_nil/1)
    |> Stream.map(fn %{"channel" => channel} = record ->
      case Integer.parse(channel) do
        {channel, ""} ->
          Map.put(record, "channel", channel)

        _ ->
          Logger.warn("Invalid channel in scan: #{channel}")
          nil
      end
    end)
    |> Stream.reject(&is_nil/1)
    |> Stream.map(fn %{"signal" => signal} = record ->
      case Integer.parse(signal) do
        {signal, ""} ->
          Map.put(record, "signal", signal)

        _ ->
          Logger.warn("Invalid signal in scan: #{signal}")
          nil
      end
    end)
    |> Stream.reject(&is_nil/1)
    |> Enum.to_list()
  end

  defp process_tshark_output(team, output) do
    cond do
      Regex.match?(~r/^\d+ /, output) ->
        Logger.warn("Observed deauth packet for team #{team}")
        Status.problem_team(team)

      true ->
        nil
    end
  end
end
