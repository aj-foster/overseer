defmodule FTC.Overseer.WLAN.Cache do
  use GenServer

  ##############
  # Client API #
  ##############

  @doc """
  Remove all teams from the cache.
  """
  @spec clear_cache() :: :ok
  def clear_cache() do
    GenServer.call(__MODULE__, :clear_cache)
  end

  @doc """
  Retrieve the channel where a team was most recently seen.
  """
  @spec get_team_channel(pos_integer) :: {:ok, pos_integer} | :error
  def get_team_channel(team) do
    GenServer.call(__MODULE__, {:get_channel, team})
  end

  @doc """
  Save a team to the cache.
  """
  @spec save_team(map) :: :ok
  def save_team(team) do
    GenServer.cast(__MODULE__, {:save_team, team})
  end

  ###########
  # Helpers #
  ###########

  # Look for a team in the cache.
  @spec get_cached_team(atom, pos_integer) :: {:ok, map} | {:error, :cache_miss}
  defp get_cached_team(table, team) do
    case :ets.lookup(table, team) do
      [{^team, data}] -> {:ok, data}
      _ -> {:error, :cache_miss}
    end
  end

  ##############
  # Server API #
  ##############

  @doc """
  Starts a GenServer with the Module's name.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  GenServer callback. Creates or finds an ETS table for caching.
  """
  @impl GenServer
  def init(_) do
    with :undefined <- :ets.info(:team_cache),
         table <- :ets.new(:team_cache, [:set, :named_table]) do
      {:ok, table}
    else
      [{:name, :team_cache} | _] -> {:ok, :team_cache}
      _ -> {:stop, :ets_error}
    end
  end

  @impl GenServer
  def handle_call({:get_channel, team}, _from, table) do
    case get_cached_team(table, team) do
      {:ok, %{"channel" => channel}} ->
        {:reply, {:ok, channel}, table}

      {:error, :cache_miss} ->
        {:reply, :not_found, table}
    end
  end

  @impl GenServer
  def handle_call(:clear_cache, _from, table) do
    :ets.delete_all_objects(table)
    {:reply, :ok, table}
  end

  @impl GenServer
  def handle_cast({:save_team, team}, table) do
    team_number = Map.fetch!(team, "team")
    :ets.insert(table, {team_number, team})

    {:noreply, table}
  end
end
