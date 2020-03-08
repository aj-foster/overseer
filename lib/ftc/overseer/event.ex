defmodule FTC.Overseer.Event do
  @moduledoc """
  Provides an event bus. Processes can subscribe to topics and produce events using the
  various helper functions.
  """
  alias FTC.PubSub, as: PS
  alias Phoenix.PubSub

  #############
  # Consumers #
  #############

  @doc """
  Subscribe to the given topic.
  """
  @spec subscribe(String.t()) :: :ok | {:error, term}
  def subscribe(topic) do
    PubSub.subscribe(PS, topic)
  end

  @doc """
  Unsubscribe from the given topic.
  """
  @spec unsubscribe(String.t()) :: :ok | {:error, term}
  def unsubscribe(topic) do
    PubSub.unsubscribe(PS, topic)
  end

  #########
  # Match #
  #########

  @doc """
  Signal the start of a match.
  """
  @spec match_started(String.t()) :: :ok | {:error, term}
  def match_started(match_name) do
    PubSub.broadcast(PS, "match", {:started, match_name})
  end

  @doc """
  Signal which teams are playing in a match.
  """
  @spec match_populated(String.t(), [pos_integer]) :: :ok | {:error, term}
  def match_populated(match_name, teams) do
    PubSub.broadcast(PS, "match", {:populated, match_name, teams})
  end

  @doc """
  Signal the end of a match.
  """
  @spec match_ended(String.t()) :: :ok | {:error, term}
  def match_ended(match_name) do
    PubSub.broadcast(PS, "match", {:ended, match_name})
  end

  @doc """
  Signal that a match was prematurely ended.
  """
  @spec match_aborted(String.t()) :: :ok | {:error, term}
  def match_aborted(match_name) do
    PubSub.broadcast(PS, "match", {:aborted, match_name})
  end

  ########
  # Team #
  ########

  @doc """
  Signal that a team is being tracked.
  """
  @spec team_found(pos_integer, pos_integer) :: :ok | {:error, term}
  def team_found(team, channel) do
    PubSub.broadcast(PS, "team", {:found, team, channel})
  end

  @doc """
  Signal that a deauthenication was observed for a team.
  """
  @spec team_deauthenticated(pos_integer, pos_integer) :: :ok | {:error, term}
  def team_deauthenticated(team, total_count) do
    PubSub.broadcast(PS, "team", {:deauthenticated, team, total_count})
  end
end
