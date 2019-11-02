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

  @spec observe(pid()) :: :ok
  def observe(adapter) do
    GenServer.cast(adapter, :observe)
  end

  @spec stop(pid()) :: :ok
  def stop(adapter) do
    GenServer.cast(adapter, :stop)
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
    |> do_scan()

    {:reply, :ok, state}
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

  @scan_line ~r/^(?<address>([A-F0-9:])*) \| (?<channel>\d+) \| (?<signal>-?\d+) \| "(?<SSID>.*)"$/
  @valid_ssid ~r/DIRECT-[[:alnum:]]+-(?<team>\d+)-/i

  defp do_scan(adapter) do
    {:ok, output} = Executor.execute("./bin/scan \"#{adapter}\"")

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
