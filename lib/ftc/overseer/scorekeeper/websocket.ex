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
  """
  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, term}
  def start_link(opts \\ []) do
    host = Scorekeeper.get_api_host()
    event = Scorekeeper.get_event_code()
    endpoint = "/api/v2/stream/?code=#{event}"

    url =
      URI.merge(host, endpoint)
      |> Map.put(:scheme, "ws")
      |> URI.to_string()

    opts =
      opts
      |> Keyword.put(:name, __MODULE__)

    WebSockex.start_link(url, __MODULE__, nil, opts)
  end

  ##########
  # Server #
  ##########

  def handle_connect(_conn, state) do
    Logger.info("Connected to Scoring API websocket")
    {:ok, state}
  end

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

  def handle_disconnect(_disconnect_map, state) do
    Logger.warn("Lost connection to Scoring API websocket. Attempting reconnect...")
    {:reconnect, state}
  end

  ###########
  # Helpers #
  ###########

  @spec process_frame(map) :: :ok
  defp process_frame(%{
         "updateType" => "MATCH_START",
         "payload" => %{
           "shortName" => match_name_str
         }
       }) do
    MatchManager.start_match(match_name_str)
  end

  defp process_frame(%{"updateType" => "MATCH_ABORT"}) do
    MatchManager.abort_match()
  end

  defp process_frame(frame) do
    Logger.debug("Dropping frame", frame: frame)
  end
end
