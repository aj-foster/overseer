defmodule FTC.Overseer.WLAN.Supervisor do
  use DynamicSupervisor

  alias FTC.Overseer.WLAN.Adapter

  @doc false
  @spec start_link(any) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initialize a new WLAN adapter with the given interface `name`.
  """
  @spec start_adapter(String.t()) :: :ok
  def start_adapter(name) do
    DynamicSupervisor.start_child(__MODULE__, {Adapter, [name: name]})
    :ok
  end

  @doc false
  @impl DynamicSupervisor
  @spec init(any()) :: {:ok, DynamicSupervisor.sup_flags()} | :ignore
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
