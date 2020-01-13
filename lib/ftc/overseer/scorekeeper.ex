defmodule FTC.Overseer.Scorekeeper do
  @moduledoc """
  Interface for the FTC Scorekeeper software.
  """
  use Retry
  require Logger

  alias FTC.Overseer.Match
  alias FTC.Overseer.Scorekeeper.Websocket

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @doc false
  def start_link(_opts) do
    Task.start_link(&init/0)
  end

  defp init do
    Logger.info("Starting websocket connection manager")

    retry with: exponential_backoff() |> cap(30_000) do
      Websocket.start_link()
    after
      {:ok, _pid} -> Process.sleep(:infinity)
    else
      _ -> :ok
    end
  end

  @doc """
  Request information from the scoring API about the current active match.
  """
  @spec get_active_match() ::
          {:ok, Match.t()}
          | {:error, HTTPoison.Error.t() | Jason.DecodeError.t()}
          | {:error, String.t(), map}
  def get_active_match() do
    host = get_api_host()
    event = get_event_code()
    endpoint = "/api/v1/events/#{event}/matches/active/"

    url =
      URI.merge(host, endpoint)
      |> URI.to_string()

    with {:ok, %HTTPoison.Response{body: body}} <- HTTPoison.get(url),
         {:ok, data} <- Jason.decode(body),
         {:ok, match} <- parse_match(data) do
      Logger.debug("Active match: #{match.name} with #{Enum.join(match.teams, ", ")}")
      {:ok, match}
    end
  end

  @doc """
  Get hostname (with no endpoint) of the scoring system.
  """
  @spec get_api_host() :: String.t() | nil
  def get_api_host() do
    Application.get_env(:overseer, :scoring_host)
  end

  @doc """
  Set scoring system host.
  """
  @spec set_api_host(String.t()) :: :ok | {:error, String.t()}
  def set_api_host(host) do
    case URI.parse(host) do
      %URI{host: nil} ->
        {:error, "Invalid hostname"}

      %URI{scheme: nil} = uri ->
        host =
          Map.put(uri, :scheme, "http")
          |> URI.to_string()

        Logger.info("Setting new scoring API host: #{host}")
        Application.put_env(:overseer, :scoring_host, host)

      %URI{} = uri ->
        host = URI.to_string(uri)
        Logger.info("Setting new scoring API host: #{host}")
        Application.put_env(:overseer, :scoring_host, host)
    end
  end

  @doc """
  Get the configured event code.
  """
  @spec get_event_code() :: String.t() | nil
  def get_event_code() do
    Application.get_env(:overseer, :scoring_event)
  end

  @doc """
  Set the event code.
  """
  @spec set_event_code(String.t()) :: :ok
  def set_event_code(event) do
    Logger.info("Setting new scoring event code: #{event}")
    Application.put_env(:overseer, :scoring_event, event)
  end

  # Extract relevant match information.
  #
  @spec parse_match(map) :: {:ok, Match.t()} | {:error, String.t(), map}
  defp parse_match(data) do
    with %{"matches" => matches} <- data,
         [match] <- filter_old_matches(matches),
         %{"field" => field, "matchName" => name} <- match,
         %{"blue" => %{"team1" => blue1, "team2" => blue2}} <- match,
         %{"red" => %{"team1" => red1, "team2" => red2}} <- match do
      {:ok,
       %Match{
         name: name,
         field: field,
         teams: [blue1, blue2, red1, red2]
       }}
    else
      result ->
        {:error, "Unexpected result", result}
    end
  end

  # Filter matches that have finished but are not committed.
  #
  defp filter_old_matches(matches) do
    matches
    |> Enum.reject(fn %{"matchState" => state} -> state == "REVIEW" end)
  end
end
