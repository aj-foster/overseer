defmodule FTC.Overseer.Scorekeeper do
  @moduledoc """
  Interface for the FTC Scorekeeper software.
  """
  require Logger

  alias FTC.Overseer.Match

  @doc """
  Request information from the scoring API about the current active match.
  """
  @spec get_active_match() ::
          {:ok, map}
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
  @spec get_api_host() :: String.t()
  def get_api_host() do
    Application.get_env(:overseer, :scoring_host, "http://localhost:8382")
  end

  @doc """
  Get the configured event code.
  """
  @spec get_event_code() :: String.t()
  def get_event_code() do
    Application.get_env(:overseer, :scoring_event, "")
  end

  # Extract relevant match information.
  #
  @spec parse_match(map) :: {:ok, map} | {:error, String.t(), map}
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
