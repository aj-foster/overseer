defmodule FTC.Overseer.MatchManager do
  use GenServer
  require Logger

  alias FTC.Overseer.MatchState
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
  def start_match(match) do
    GenServer.cast(__MODULE__, {:start, match})
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
    {:ok, %MatchState{}}
  end

  def handle_cast({:start, match_name}, _state) do
    Logger.info("Match start: #{match_name}")
    Process.send_after(self(), :stop, @match_length_ms)

    case Scorekeeper.get_active_match() do
      {:ok, %{name: ^match_name}} ->
        {:noreply, %{}}

      {:ok, %{name: name}} ->
        Logger.error("Expected match #{match_name} but current active match is #{name}")
        {:noreply, %{}}

      _ ->
        {:noreply, %{}}
    end
  end

  def handle_cast(:abort, %{state: :active, match: match}) do
    Logger.info("Match abort: #{match}")
    {:noreply, %MatchState{}}
  end

  def handle_info(:stop, %MatchState{state: :active, match: match}) do
    Logger.info("Match end: #{match}")
    {:noreply, %MatchState{}}
  end
end
