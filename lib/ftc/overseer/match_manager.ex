defmodule FTC.Overseer.MatchManager do
  use GenServer
  require Logger

  alias FTC.Overseer.Event
  alias FTC.Overseer.Match
  alias FTC.Overseer.Scorekeeper

  # Total time: authonomous + changeover + teleop
  @match_length_ms (30 + 8 + 120) * 1000

  ##########
  # Client #
  ##########

  @doc """
  Start GenServer for tracking the status of the currently active match.
  """
  @spec start_link(any) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Mark the beginning of the given match.
  """
  @spec start_match(String.t()) :: :ok
  def start_match(match_name) do
    GenServer.cast(__MODULE__, {:start, match_name})
  end

  @doc """
  Mark the premature end of the current match.
  """
  @spec abort_match() :: :ok
  def abort_match() do
    GenServer.cast(__MODULE__, :abort)
  end

  @doc """
  Get information about the current match.
  """
  @spec get_match() :: {:ok, Match.t()} | {:error, String.t()}
  def get_match() do
    GenServer.call(__MODULE__, :get)
  end

  ##########
  # Server #
  ##########

  @spec init(any) :: {:ok, MatchState.t()}
  def init(_opts) do
    :ok = Event.subscribe("match")
    {:ok, :inactive}
  end

  def handle_call(:get, _from, :inactive), do: {:reply, {:error, "No active match"}, :inactive}
  def handle_call(:get, _from, state), do: {:reply, {:ok, state}, state}

  def handle_info({:started, match_name}, _state) do
    timer = Process.send_after(self(), :stop, @match_length_ms)

    case Scorekeeper.get_active_match() do
      {:ok, %Match{name: ^match_name, teams: teams} = match} ->
        Event.match_populated(match_name, teams)
        {:noreply, %{match | timer: timer}}

      {:ok, %Match{name: name, teams: teams} = match} ->
        Logger.error("Expected match #{match_name} but current active match is #{name}")

        Event.match_populated(match_name, teams)
        {:noreply, %{match | timer: timer}}

      other ->
        Logger.error("Could not get data for active match. Got #{inspect(other)}")
        Process.cancel_timer(timer)
        {:noreply, :inactive}
    end
  end

  def handle_info({:aborted, match_name}, %Match{name: match_name, timer: timer}) do
    Process.cancel_timer(timer)
    {:noreply, :inactive}
  end

  def handle_info(:stop, %Match{name: name}) do
    Event.match_ended(name)
    {:noreply, :inactive}
  end

  def handle_info(:stop, _state) do
    Logger.info("Match end: [unknown]")
    {:noreply, :inactive}
  end

  def handle_info(_message, state), do: {:noreply, state}
end
