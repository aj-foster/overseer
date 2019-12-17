defmodule FTC.Display.StatusLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(FTC.Display.PageView, "index.html", assigns)
  end

  def mount(_, socket) do
    Phoenix.PubSub.subscribe(FTC.Display.PubSub, "status")

    socket =
      socket
      |> assign(:status, "Ready")
      |> assign(:match, "??")
      |> assign(:teams, [])

    {:ok, socket}
  end

  def handle_info({:start, match_name}, socket) do
    socket =
      socket
      |> assign(:status, "Match started")
      |> assign(:match, match_name)

    {:noreply, socket}
  end

  def handle_info(:stop, socket) do
    socket =
      socket
      |> assign(:status, "Match ended")

    {:noreply, socket}
  end
end
