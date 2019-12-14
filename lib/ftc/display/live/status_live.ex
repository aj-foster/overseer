defmodule FTC.Display.StatusLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    Status: <%= @status %>
    """
  end

  def mount(_, socket) do
    status = "Ready"
    {:ok, assign(socket, :status, status)}
  end
end
