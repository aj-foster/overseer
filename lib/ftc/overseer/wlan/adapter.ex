defmodule FTC.Overseer.WLAN.Adapter do
  use GenServer
  require Logger

  alias FTC.Overseer.AdapterState
  alias FTC.Overseer.Executor

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

  @spec observe(pid, pos_integer) :: :ok
  def observe(adapter, team, opts \\ []) do
    GenServer.cast(adapter, {:start, team, opts[:temp] || []})
  end

  @spec scan(pid) :: {:ok, [map]} | :error
  def scan(adapter) do
    GenServer.call(adapter, :scan)
  end

  @spec stop(pid) :: :ok
  def stop(adapter) do
    GenServer.cast(adapter, :stop)
  end

  ##########
  # Server #
  ##########

  @spec init(Keyword.t()) :: {:ok, AdapterState.t()}
  def init(opts) do
    Executor.execute("ifconfig #{opts[:name]} down")
    Executor.execute("iwconfig #{opts[:name]} mode monitor")
    Executor.execute("ifconfig #{opts[:name]} up")
    {:ok, %AdapterState{name: opts[:name], channel: nil, active_pid: nil}}
  end

  def handle_cast({:start, team, _other_teams}, state) do
    Process.send(self(), :observe, [])
    {:noreply, %{state | team: team}}
  end

  def handle_cast(:stop, %{active_pid: pid} = state) when is_pid(pid) do
    Executor.stop(pid)
    {:noreply, %{state | team: nil, active_pid: nil, channel: nil}}
  end

  def handle_cast(:stop, state) do
    {:noreply, %{state | team: nil, active_pid: nil, channel: nil}}
  end

  def handle_info(:observe, %{team: team} = state) when is_nil(team) do
    {:noreply, state}
  end

  def handle_info(:observe, %{name: name, team: team} = state) do
    do_scan(name)
    |> Enum.filter(fn %{"team" => team_number} -> team_number == team end)
    |> Enum.sort_by(fn %{"signal" => signal} -> signal end)
    |> List.first()
    |> case do
      %{"channel" => channel} ->
        Logger.debug("Team #{team} found on channel #{channel}")
        {:noreply, %{state | team: team, channel: channel}}

      _ ->
        Logger.warn("Team #{team} not found in scan")
        Process.send_after(self(), :observe, 1000)
        {:noreply, %{state | team: team}}
    end
  end

  ###########
  # Helpers #
  ###########

  @scan_line ~r/^(?<address>([A-F0-9:])*) \| (?<channel>\d+) \| (?<signal>-?\d+) \| "(?<SSID>.*)"$/
  @valid_ssid ~r/DIRECT-[[:alnum:]]+-(?<team>\d+)-/i

  @spec do_scan(String.t()) :: list
  defp do_scan(adapter_name) do
    case Executor.execute("./bin/scan \"#{adapter_name}\"") do
      {:ok, output} -> process_output(output)
      {:error, _output, _code} -> []
    end
  end

  @spec process_output(String.t()) :: list
  defp process_output(output) do
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
end
