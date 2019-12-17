defmodule FTC.Display.Status do
  @moduledoc """
  Provides helpers for communicating the status of matches in progress.
  """
  alias FTC.Display.PubSub, as: PS
  alias Phoenix.PubSub

  @doc """
  Indicate that match `name` has begun.
  """
  @spec start_match(String.t()) :: :ok | {:error, term}
  def start_match(name) do
    PubSub.broadcast(PS, "status", {:start, name})
  end

  @doc """
  Set which teams are currently playing.
  """
  @spec set_teams([pos_integer]) :: :ok | {:error, term}
  def set_teams(teams) when length(teams) == 4 do
    PubSub.broadcast(PS, "status", {:teams, teams})
  end

  @doc """
  Indicate that the match has ended.
  """
  @spec stop_match() :: :ok | {:error, term}
  def stop_match do
    PubSub.broadcast(PS, "status", :stop)
  end

  @doc """
  Indicate that the match was aborted.
  """
  @spec abort_match() :: :ok | {:error, term}
  def abort_match do
    PubSub.broadcast(PS, "status", :abort)
  end
end
