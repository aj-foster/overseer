defmodule FTC.Overseer.Scorekeeper.MockSocket do
  use Phoenix.Socket, log: :debug

  @doc false
  @spec connect(map, Phoenix.Socket.t(), map) :: {:ok, Phoenix.Socket.t()}
  def connect(%{"code" => event_code}, socket, _conn_info) do
    {:ok, assign(socket, :event, event_code)}
  end

  def connect(_params, socket, _conn_info), do: {:ok, socket}

  @doc false
  @spec id(Phoenix.Socket.t()) :: String.t()
  def id(socket), do: "event:#{socket.assigns.event}"

  @doc """
  Broadcast a message to all sockets that subscribed to a the given event. The `message` can be
  any JSON-encodable data.
  """
  @spec broadcast(String.t(), any) :: :ok | {:error, any}
  def broadcast(event, message) do
    Phoenix.PubSub.broadcast(
      FTC.Overseer.PubSub,
      "event:#{event}",
      {:socket_push, :text, Jason.encode!(message)}
    )
  end
end
