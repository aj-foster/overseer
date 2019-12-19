defmodule FTC.Overseer.Executor.MockReceiver do
  @moduledoc false
  #
  # Provides a fake shell spawner for use in development and testing.
  #
  use GenServer, restart: :temporary
  require Logger

  alias FTC.Overseer.Executor
  alias FTC.Overseer.Executor.Runner

  @type on_exit() :: (integer, non_neg_integer() -> any)
  @type on_output() :: (integer, String.t() -> any)

  @type option ::
          {:command, String.t()}
          | {:id, integer}
          | {:on_exit, on_exit()}
          | {:on_output, on_output()}
          | Runner.option()

  @type opts :: [option()]

  @doc false
  @spec start_link(opts) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @doc """
  Produce a fake deauthentication notice for the first tshark process in the executor list.
  """
  @spec deauth :: :ok
  def deauth do
    {_id, pid, _type, _modules} =
      DynamicSupervisor.which_children(Executor)
      |> Enum.random()

    GenServer.call(pid, :deauth)
  end

  @doc false
  @spec init(opts()) :: {:ok, opts()}
  def init(opts) do
    initial_output = """
    Running as user "root" and group "root". This could be dangerous.
    """

    opts[:on_output].(opts[:id], initial_output)
    {:ok, opts}
  end

  @doc false
  @spec handle_call(:deauth, {pid, any}, opts) :: {:reply, :ok, opts}
  def handle_call(:deauth, _from, opts) do
    output = """
    1 00:00:00:00:00:01 00:00:00:00:00:11
    """

    opts[:on_output].(opts[:id], output)
    {:reply, :ok, opts}
  end

  @spec handle_call(:exit, {pid, any}, opts) :: {:stop, :normal, :ok, opts}
  def handle_call(:exit, _from, opts) do
    opts[:on_exit].(opts[:id], 0)
    {:stop, :normal, :ok, opts}
  end
end
