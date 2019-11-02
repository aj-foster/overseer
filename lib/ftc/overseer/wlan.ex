defmodule FTC.Overseer.WLAN do
  use Supervisor

  alias FTC.Overseer.WLAN.Manager
  alias FTC.Overseer.WLAN.Supervisor, as: AdapterSupervisor

  @doc false
  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, any}
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  @impl true
  def init(_opts) do
    children = [
      AdapterSupervisor,
      Manager
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
