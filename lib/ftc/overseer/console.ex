defmodule FTC.Overseer.Console do
  @moduledoc """
  Provides an SSH console using a well-known password.

  Taken in part from https://github.com/nerves-project/nerves_init_gadget/
  """
  use GenServer

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts], name: __MODULE__)
  end

  def init(_opts) do
    {:ok, ssh} =
      :ssh.daemon(22, [
        {:password, 'overseer'},
        {:system_dir, :code.priv_dir(:nerves_firmware_ssh)},
        {:shell, {Elixir.IEx, :start, []}}
      ])

    Process.link(ssh)
    {:ok, ssh}
  end
end
