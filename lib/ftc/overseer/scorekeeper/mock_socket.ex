defmodule FTC.Overseer.Scorekeeper.MockSocket do
  use Phoenix.Socket, log: :debug

  def connect(_params, socket, _conn_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
