defmodule FTC.Overseer.Match do
  @moduledoc """
  Provides a `%Match{}` struct for wrapping information about a current active match.
  """

  defstruct [:name, :field, :teams]
  @type t :: %__MODULE__{name: String.t(), field: pos_integer, teams: [pos_integer]}
end
