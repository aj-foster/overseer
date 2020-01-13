defmodule FTC.Overseer.Adapter.State do
  @moduledoc """
  Provides a struct to hold the state of a wireless adapter and its driving process.
  """

  @typedoc """
  State of a wireless adapter and its driving process.
  """
  @type t :: %__MODULE__{
          active_pid: pid | nil,
          bssid: String.t() | nil,
          channel: pos_integer | nil,
          name: String.t(),
          team: pos_integer | nil
        }
  defstruct [:name, :channel, :active_pid, :team, :bssid]
end
