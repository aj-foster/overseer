defmodule FTC.Overseer.Scorekeeper.Websocket do
  @moduledoc """
  Manager of a websocket connection with the FTC Scorekeeper software.

  Uses the `/api/v2/stream/` endpoint to receive notifications of match starts and aborts.
  """
  use WebSockex
  require Logger

  alias FTC.Overseer.Event
  alias FTC.Overseer.Scorekeeper

  ##########
  # Client #
  ##########

  @doc """
  Create a websocket connection to the scoring API.

  ## Options

    * `:event`: (string, default set in configuration) Overrides the `:scoring_event` configuration
      for which we stream events

    * `:name`: (atom, default `__MODULE__`) Name to give the websocket process

  All other options are passed directly to `Websockex.start_link/4`.
  """
  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, term}
  def start_link(opts \\ []) do
    host = Scorekeeper.get_api_host()
    event = opts[:event] || Scorekeeper.get_event_code()

    case {host, event} do
      {nil, _} ->
        {:error, "Scoring host not set"}

      {_, nil} ->
        {:error, "Scoring event code not set"}

      {host, event} ->
        endpoint = "/api/v2/stream/?code=#{event}"

        url =
          URI.merge(host, endpoint)
          |> Map.put(:scheme, "ws")
          |> URI.to_string()

        opts = Keyword.put_new(opts, :name, __MODULE__)
        websocket_opts = Keyword.drop(opts, [:event])

        Logger.info("Attempting to connect to Scoring API websocket...")
        WebSockex.start_link(url, __MODULE__, opts, websocket_opts)
    end
  end

  @doc """
  Terminate the connection. This may be used to restart the websocket on a different host.
  """
  @spec close :: :ok
  def close() do
    WebSockex.cast(__MODULE__, :close)
  end

  ##########
  # Server #
  ##########

  @doc false
  def handle_connect(_conn, state) do
    Logger.info("Connected to Scoring API websocket")
    {:ok, state}
  end

  @doc false
  def handle_frame({:text, message}, state) do
    Logger.debug("Received Websocket Frame: #{message}")

    with {:ok, data} <- Jason.decode(message),
         :ok <- process_frame(data) do
      {:ok, state}
    else
      {:error, %Jason.DecodeError{}} ->
        Logger.warn("Problem decoding websocket frame: #{message}")
        {:ok, state}

      :error ->
        {:ok, state}
    end
  end

  @doc false
  def handle_disconnect(_disconnect_map, state) do
    Logger.warn("Lost connection to Scoring API websocket. Attempting reconnect...")
    {:reconnect, state}
  end

  @doc false
  def handle_info(:close, state) do
    {:close, state}
  end

  ###########
  # Helpers #
  ###########

  @spec process_frame(map) :: :ok | {:error, term}
  defp process_frame(%{
         "updateType" => "MATCH_START",
         "payload" => %{
           "shortName" => match_name_str
         }
       }) do
    Event.match_started(match_name_str)
  end

  defp process_frame(%{
         "updateType" => "MATCH_ABORT",
         "payload" => %{
           "shortName" => match_name_str
         }
       }) do
    Event.match_aborted(match_name_str)
  end

  defp process_frame(frame) do
    Logger.debug("Dropping frame", frame: frame)
  end
end
