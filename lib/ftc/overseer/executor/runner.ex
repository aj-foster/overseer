defmodule FTC.Overseer.Executor.Runner do
  @moduledoc false
  require Logger

  @type option() ::
          {:executable, String.t()}
          | {:receiver, pid()}

  @type opts() :: [option()]

  @spec config(Keyword.t()) :: opts()
  defp config(opts) do
    executable = opts[:executable] || "echo"
    receiver = configure_receiver(opts[:receiver])

    [
      executable: executable,
      receiver: receiver
    ]
  end

  # Use a string as the Collectable receiver of output unless a PID was given.
  #
  @spec configure_receiver(pid() | nil) :: Enumerable.t() | <<>>
  defp configure_receiver(pid) when is_pid(pid), do: IO.stream(pid, :line)
  defp configure_receiver(_), do: ""

  @doc """
  Execute a command synchronously and return the results.

  If the command has an exit code of `0`, this will return `{:ok, output}`. Otherwise it will
  return `{:error, output, code}`.

  ## Options

    * `:executable`: (optional, default `kubectl`) Name of the executable to run

    * `:receiver`: (optional) PID of the process that should receive output via `IO.Stream`
  """
  @spec run(String.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, String.t(), pos_integer}
  def run(command, opts \\ []) do
    opts = config(opts)
    sh_exec(command, opts)
  end

  @spec sh_exec(String.t(), opts()) ::
          {:ok, String.t()} | {:error, String.t(), pos_integer}
  defp sh_exec(command, opts) do
    case System.cmd("sh", ["-c", command], stderr_to_stdout: true, into: opts[:receiver]) do
      {output, 0} -> {:ok, output}
      {output, code} -> {:error, output, code}
    end
  end

  @doc """
  Start a command execution process and link it to the current process.

  See run/3 for more information about the arguments and options.
  """
  @spec start_link({String.t(), Keyword.t()}) :: pid()
  def start_link({command, opts}) do
    opts = config(opts)
    caller = self()

    Process.spawn(
      fn ->
        case sh_exec(command, opts) do
          {:ok, _output} -> Process.send(caller, {:exit, 0}, [])
          {:error, _output, code} -> Process.send(caller, {:exit, code}, [])
        end
      end,
      [:link]
    )
  end
end
