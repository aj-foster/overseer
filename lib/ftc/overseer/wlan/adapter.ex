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
    GenServer.cast(adapter, {:observe, team, opts[:temp] || []})
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

  def handle_call(:scan, _from, %{name: _name} = state) do
    {:reply, nil, state}
  end

  def handle_cast({:observe, team, _other_teams}, %{name: name} = state) do
    do_scan(name)
    |> Enum.filter(fn %{"team" => team_number} -> team_number == team end)
    |> Enum.sort_by(fn %{"signal" => signal} -> signal end)
    |> List.first()
    |> case do
      %{"channel" => channel} ->
        Executor.execute("iwconfig #{name} #{channel}")
        {:noreply, %{state | team: team, channel: channel}}

      _ ->
        Logger.warn("Team #{team} not found in initial scan")
        {:noreply, %{state | team: team}}
    end
  end

  def handle_cast(:stop, %{active_pid: pid} = state) do
    Executor.stop(pid)
    {:noreply, %{state | team: nil, active_pid: nil, channel: nil}}
  end

  ###########
  # Helpers #
  ###########

  @scan_line ~r/^(?<address>([A-F0-9:])*) \| (?<channel>\d+) \| (?<signal>-?\d+) \| "(?<SSID>.*)"$/
  @valid_ssid ~r/DIRECT-[[:alnum:]]+-(?<team>\d+)-/i

  defp do_scan(adapter_name) do
    {:ok, output} = Executor.execute("./bin/scan \"#{adapter_name}\"")

    String.split(output, "\n", trim: true)
    |> Stream.map(fn line -> Regex.named_captures(@scan_line, line) end)
    |> Stream.reject(&is_nil/1)
    |> Stream.map(fn %{"ssid" => ssid} = record ->
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
  end
end
