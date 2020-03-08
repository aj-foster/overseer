defmodule FTC.Overseer.Match.State do
  @moduledoc """
  Provides a struct for wrapping information about the current active match.
  """

  defstruct [:name, :field, :teams, :timer]

  @type t ::
          %__MODULE__{
            name: String.t(),
            field: pos_integer,
            teams: [pos_integer],
            timer: reference | nil
          }
          | :inactive
end
