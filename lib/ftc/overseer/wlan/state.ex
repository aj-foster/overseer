defmodule FTC.Overseer.Adapter.State do
  @moduledoc """
  Provides a struct to hold the state of a wireless adapter and its driving process.
  """

  @typedoc """
  State of a wireless adapter and its driving process.
  """
  @type t :: %__MODULE__{
          active_pid: pid,
          bssid: String.t(),
          channel: pos_integer,
          name: String.t(),
          team: pos_integer
        }
  defstruct [:name, :channel, :active_pid, :team, :bssid]
end
