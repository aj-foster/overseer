defmodule FTC.Overseer.Event.Logger do
  use GenServer
  require Logger

  alias FTC.Overseer.Event

  ##########
  # Client #
  ##########

  @doc """
  Start the event logger process.
  """
  @spec start_link(any) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  ##########
  # Server #
  ##########

  @doc false
  @spec init(any) :: {:ok, nil}
  def init(_opts) do
    :ok = Event.subscribe("match")
    :ok = Event.subscribe("team")
    {:ok, nil}
  end

  # Match

  def handle_info({:started, match_name}, state) do
    Logger.info("Match start: #{match_name}")
    {:noreply, state}
  end

  def handle_info({:populated, match_name, teams}, state) do
    Logger.info("Match populated: #{match_name} (teams #{inspect(teams)})")
    {:noreply, state}
  end

  def handle_info({:ended, match_name}, state) do
    Logger.info("Match end: #{match_name}")
    {:noreply, state}
  end

  def handle_info({:aborted, match_name}, state) do
    Logger.info("Match aborted: #{match_name}")
    {:noreply, state}
  end

  # Team

  def handle_info({:found, team, channel}, state) do
    Logger.info("Team found: #{team} (ch. #{channel})")
    {:noreply, state}
  end

  def handle_info({:deauthenticated, team, total_count}, state) do
    Logger.warn("Team deauthenticated: #{team} (##{total_count})")
    {:noreply, state}
  end

  # Catch-all

  def handle_info(_message, state), do: {:noreply, state}
end
