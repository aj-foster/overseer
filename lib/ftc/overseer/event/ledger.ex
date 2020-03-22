defmodule FTC.Overseer.Event.Ledger do
  use GenServer
  require Logger

  alias FTC.Overseer.Event

  ##########
  # Client #
  ##########

  @doc """
  Start the ledger process.
  """
  @spec start_link(any) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get information about a particular team from the given match.
  """
  @spec get_team(String.t(), pos_integer) :: {:ok, map} | {:error, :not_found}
  def get_team(match, team) do
    case GenServer.call(__MODULE__, {:get, match, team}) do
      %{} = team_info ->
        {:ok, team_info}

      _ ->
        {:error, :not_found}
    end
  end

  ##########
  # Server #
  ##########

  @doc false
  @spec init(any) :: {:ok, {:ets.tab(), nil}} | {:stop, :ets_error}
  def init(_opts) do
    :ok = Event.subscribe("match")
    :ok = Event.subscribe("team")

    with :undefined <- :ets.info(:ledger),
         table <- :ets.new(:ledger, [:set, :named_table]) do
      {:ok, {table, nil}}
    else
      [{:name, :ledger} | _] -> {:ok, :ledger}
      _ -> {:stop, :ets_error}
    end
  end

  # Getters

  def handle_call({:get, match, team}, _from, {ledger, current_match}) do
    with [{^match, teams, _log}] <- :ets.lookup(ledger, match),
         {:ok, team_info} <- Map.fetch(teams, team) do
      {:reply, team_info, {ledger, current_match}}
    else
      _ -> {:reply, nil, {ledger, current_match}}
    end
  end

  # Match

  def handle_info({:started, match}, {ledger, _match}) do
    :ets.insert_new(ledger, {match, %{}, %{started: DateTime.utc_now()}})
    {:noreply, {ledger, match}}
  end

  def handle_info({:populated, match, teams}, {ledger, current_match}) do
    teams =
      Enum.reduce(teams, %{}, fn team, teams ->
        Map.put(teams, team, %{})
      end)

    case :ets.lookup(ledger, match) do
      [{^match, %{}, log}] ->
        :ets.insert(ledger, {match, teams, log})

      [] ->
        :ets.insert_new(ledger, {match, teams, %{}})

      _ ->
        nil
    end

    {:noreply, {ledger, current_match}}
  end

  def handle_info({:ended, match}, {ledger, current_match}) do
    case :ets.lookup(ledger, match) do
      [{^match, teams, log}] ->
        log = Map.put(log, :ended, DateTime.utc_now())
        :ets.insert(ledger, {match, teams, log})

      [] ->
        :ets.insert_new(ledger, {match, %{}, %{ended: DateTime.utc_now()}})

      _ ->
        nil
    end

    {:noreply, {ledger, current_match}}
  end

  def handle_info({:aborted, match_name}, {ledger, match}) do
    case :ets.lookup(ledger, match_name) do
      [{^match_name, teams, log}] ->
        log = Map.put(log, :aborted, DateTime.utc_now())
        :ets.insert(ledger, {match_name, teams, log})

      [] ->
        :ets.insert_new(ledger, {match_name, %{}, %{aborted: DateTime.utc_now()}})

      _ ->
        nil
    end

    {:noreply, {ledger, match}}
  end

  # Team

  def handle_info({:found, team_number, channel}, {ledger, match}) do
    team_info = %{channel: channel}

    with [{^match, teams, log}] <- :ets.lookup(ledger, match),
         {:ok, team} <- Map.fetch(teams, team_number) do
      teams = Map.put(teams, team_number, Map.merge(team, team_info))
      :ets.insert(ledger, {match, teams, log})
    else
      [] ->
        :ets.insert_new(ledger, {match, %{team_number => team_info}, %{}})

      _ ->
        nil
    end

    {:noreply, {ledger, match}}
  end

  def handle_info({:deauthenticated, team_number, total_count}, {ledger, match}) do
    team_info = %{packets: total_count}

    with [{^match, teams, log}] <- :ets.lookup(ledger, match),
         {:ok, team} <- Map.fetch(teams, team_number) do
      teams = Map.put(teams, team_number, Map.merge(team, team_info))
      :ets.insert(ledger, {match, teams, log})
    else
      [] ->
        :ets.insert_new(ledger, {match, %{team_number => team_info}, %{}})

      _ ->
        nil
    end

    {:noreply, {ledger, match}}
  end

  # Catch-all

  def handle_info(_message, {ledger, match}), do: {:noreply, {ledger, match}}
end
