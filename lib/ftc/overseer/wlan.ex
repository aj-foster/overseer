defmodule FTC.Overseer.WLAN do
  @moduledoc """
  Supervisor for the WLAN adapters and their managing process.
  """
  use Supervisor

  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, any}
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      FTC.Overseer.WLAN.Supervisor,
      FTC.Overseer.WLAN.Manager
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
