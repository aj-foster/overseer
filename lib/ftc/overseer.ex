defmodule FTC.Overseer do
  @moduledoc """
  Provides convenience functions for administering the Overseer application.
  """

  defdelegate set_api_host(host), to: FTC.Overseer.Scorekeeper
  defdelegate set_event_code(code), to: FTC.Overseer.Scorekeeper

  @doc """
  Stop the application.
  """
  def shutdown do
    :init.stop()
  end
end
