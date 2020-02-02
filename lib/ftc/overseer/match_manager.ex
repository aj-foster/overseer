defmodule FTC.Overseer.MatchManager do
  use GenServer
  require Logger

  alias FTC.Display.Status
  alias FTC.Overseer.Match
  alias FTC.Overseer.Scorekeeper
  alias FTC.Overseer.WLAN

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

  ##########
  # Server #
  ##########

  @spec init(any) :: {:ok, MatchState.t()}
  def init(_opts) do
    {:ok, :inactive}
  end

  def handle_cast({:start, match_name}, _state) do
    Logger.info("Match start: #{match_name}")
    Status.start_match(match_name)
    timer = Process.send_after(self(), :stop, @match_length_ms)

    case Scorekeeper.get_active_match() do
      {:ok, %Match{name: ^match_name, teams: teams} = match} ->
        Status.set_teams(teams)
        WLAN.observe(teams)
        {:noreply, %{match | timer: timer}}

      {:ok, %Match{name: name, teams: teams} = match} ->
        Logger.error("Expected match #{match_name} but current active match is #{name}")

        Status.set_teams(teams)
        WLAN.observe(teams)
        {:noreply, %{match | timer: timer}}

      other ->
        Logger.error("Could not get data for active match. Got #{inspect(other)}")
        Process.cancel_timer(timer)
        {:noreply, :inactive}
    end
  end

  def handle_cast(:abort, %Match{name: name, timer: timer}) do
    Logger.info("Match abort: #{name}")
    Process.cancel_timer(timer)
    Status.abort_match()

    WLAN.stop_all()
    {:noreply, :inactive}
  end

  def handle_info(:stop, %Match{name: name}) do
    Logger.info("Match end: #{name}")
    Status.stop_match()

    WLAN.stop_all()
    {:noreply, :inactive}
  end

  def handle_info(:stop, _state) do
    Logger.info("Match end: [unknown]")

    WLAN.stop_all()
    {:noreply, :inactive}
  end
end
