defmodule FTC.Overseer.Scorekeeper.Websocket do
  @moduledoc """
  Manager of a websocket connection with the FTC Scorekeeper software.

  Uses the `/api/v2/stream/` endpoint to receive notifications of match starts and aborts.
  """
  use WebSockex
  require Logger

  alias FTC.Overseer.MatchManager
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

    * `:on_abort`: (function, default `&MatchManager.start_match/1`) Function to run when a match
      is aborted

    * `:on_start`: (function, default `&MatchManager.start_match/1`) Function to run when a match
      begins

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

        opts =
          opts
          |> Keyword.put_new(:name, __MODULE__)
          |> Keyword.put_new(:on_abort, &MatchManager.abort_match/0)
          |> Keyword.put_new(:on_start, &MatchManager.start_match/1)

        websocket_opts = Keyword.drop(opts, [:event, :on_abort, :on_start])

        Logger.info("Attempting to connect to Scoring API websocket...")
        WebSockex.start_link(url, __MODULE__, opts, websocket_opts)
    end
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
         :ok <- process_frame(data, state[:on_start], state[:on_abort]) do
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

  ###########
  # Helpers #
  ###########

  @spec process_frame(map, fun, fun) :: :ok
  defp process_frame(
         %{
           "updateType" => "MATCH_START",
           "payload" => %{
             "shortName" => match_name_str
           }
         },
         start_match,
         _abort_match
       ) do
    start_match.(match_name_str)
  end

  defp process_frame(%{"updateType" => "MATCH_ABORT"}, _start_match, abort_match) do
    abort_match.()
  end

  defp process_frame(frame, _start_match, _abort_match) do
    Logger.debug("Dropping frame", frame: frame)
  end
end
