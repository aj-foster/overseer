defmodule FTC.Overseer.Executor do
  @moduledoc """
  Provides an interface for executing shell commands.

  There are two options for executing commands: `execute/2` for synchronous, blocking calls and
  `spawn/3` for asynchonous, non-blocking calls. All output from the comamnds (including both stdout
  and stderr) will be placed into a single stream.
  """
  use DynamicSupervisor

  alias FTC.Overseer.Executor.{Receiver, Runner}

  @doc """
  Starts a DynamicSupervisor for managing long-lived shell commands.
  """
  @spec start_link(any) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Execute a command synchronously and return the results.

  If the command has an exit code of `0`, this will return `{:ok, output}`. Otherwise it will
  return `{:error, output, code}`.

  ## Options

    * `:executable`: (optional, default `kubectl`) Name of the executable to run

    * `:receiver`: (optional) PID of the process that should receive output via `IO.Stream`

  ## Examples

      iex> FTC.Overseer.Executor.execute("ls")
      {:ok, "..."}

      iex> FTC.Overseer.Executor.execute("ls /nonexistent")
      {:error, "...", 1}

  """
  @spec execute(String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, String.t(), pos_integer}
  def execute(command, opts \\ []) do
    Runner.run(command, opts)
  end

  @doc """
  Execute a command asynchronously.

  ## Options

  This function accepts all of the options listed in `execute/2` as well as the following:

    * `:on_exit`: (optional) Function to run when the spawned process exits. The function should
      accept two arguments: the `id` of the spawned process and the exit code.

    * `:on_output`: (optional) Function to run when the spawn process produces output. The function
      should accept two arguments: the `id` of the spawned process and the output as a string.
  """
  @spec spawn(String.t(), String.t(), Keyword.t()) :: :ok
  def spawn(command, id, opts \\ []) do
    opts =
      opts
      |> Keyword.put(:command, command)
      |> Keyword.put(:id, id)
      |> Keyword.put_new(:on_exit, & &1)
      |> Keyword.put_new(:on_output, & &1)

    DynamicSupervisor.start_child(__MODULE__, {Receiver, opts})
    :ok
  end

  @doc """
  Callback for the initialization of the DynamicSupervisor.
  """
  @impl true
  @spec init(any()) :: {:ok, DynamicSupervisor.sup_flags()} | :ignore
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
