defmodule FTC.Overseer.WLAN.Manager do
  use GenServer
  require Logger

  alias FTC.Overseer.Executor
  alias FTC.Overseer.WLAN.Supervisor, as: AdapterSupervisor

  @typep state :: [String.t()]

  @spec start_link(any) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(_opts \\ []) do
    adapters = list_adapters()

    case length(adapters) do
      0 ->
        Logger.warn("No WLAN adapters found")

      1 ->
        Logger.info("Found 1 WLAN adapter: #{Enum.at(adapters, 0)}")

      num ->
        Logger.info("Found #{num} WLAN adapters: #{Enum.join(adapters, ", ")}")
    end

    GenServer.start_link(__MODULE__, adapters, name: __MODULE__)
  end

  @spec init([String.t()]) :: {:ok, state}
  def init(adapters) do
    Enum.each(adapters, fn adapter ->
      AdapterSupervisor.start_adapter(adapter)
    end)

    {:ok, adapters}
  end

  ###########
  # Helpers #
  ###########

  defp list_adapters() do
    {:ok, output} = Executor.execute("iwconfig 2>/dev/null | grep 'IEEE 802.11' | cut -d' ' -f 1")

    output
    |> String.trim()
    |> String.split(~r/\s/, trim: true)
  end
end
