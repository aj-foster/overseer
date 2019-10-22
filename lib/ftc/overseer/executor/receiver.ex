defmodule FTC.Overseer.Executor.Receiver do
  @moduledoc """
  Defines a process to receive and forward output from a spawned command.

  Spawned commands can asynchronously send their output to another process, however this requires
  a tight contract of messages to be passed back and forth. The server defined in this module
  normalizes the communication so that a destination process can ignore the intricacies of the
  communication.
  """
  use GenServer, restart: :temporary

  require Logger

  alias FTC.Overseer.Executor.Runner

  @type on_exit() :: (String.t(), non_neg_integer() -> any)
  @type on_output() :: (String.t(), String.t() -> any)

  @type option ::
          {:command, String.t()}
          | {:id, String.t()}
          | {:on_exit, on_exit()}
          | {:on_output, on_output()}
          | Runner.option()

  @type opts :: [option()]

  @doc """
  Start a receiver for output from a spawned command.

  Output from the command will be normalized and forwarded to the `destination` process.
  """
  @spec start_link(opts()) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @doc false
  @spec init(opts()) :: {:ok, opts()}
  def init(opts) do
    command = opts[:command] || ""
    opts = Keyword.put(opts, :receiver, self())

    Runner.start_link({command, opts})
    {:ok, opts}
  end

  # Output sent via an IO.Stream has this form.
  #
  @doc false
  @spec handle_info({:io_request, pid(), reference(), {:put_chars, :unicode, binary()}}, opts()) ::
          {:noreply, opts()}
  def handle_info({:io_request, from, ref, {:put_chars, :unicode, chars}}, opts) do
    Logger.debug("COMMAND #{opts[:id]}: #{chars}")

    # Must reply to continue the dialogue.
    Process.send(from, {:io_reply, ref, :ok}, [])

    # Forward the output to the receiver.
    opts[:on_output].(opts[:id], chars)

    {:noreply, opts}
  end

  @spec handle_info({:exit, non_neg_integer()}, opts()) :: {:stop, :normal, opts()}
  def handle_info({:exit, exit_code}, opts) do
    opts[:on_exit].(opts[:id], exit_code)
    {:stop, :normal, opts}
  end
end
