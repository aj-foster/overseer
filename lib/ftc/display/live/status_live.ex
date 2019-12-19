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
      |> assign(:match, "")
      |> assign(:teams, [0, 0, 0, 0])
      |> assign(:statuses, %{})

    {:ok, socket}
  end

  def handle_info({:start, match_name}, socket) do
    socket =
      socket
      |> assign(:status, "In Progress")
      |> assign(:match, match_name)

    {:noreply, socket}
  end

  def handle_info(:stop, socket) do
    socket =
      socket
      |> assign(:status, "Finished")

    {:noreply, socket}
  end

  def handle_info(:abort, socket) do
    socket =
      socket
      |> assign(:status, "Aborted")

    {:noreply, socket}
  end

  def handle_info({:teams, [blue1, blue2, red1, red2]}, socket) do
    s = "searching"

    socket =
      socket
      |> assign(:teams, [red1, blue1, red2, blue2])
      |> assign(:statuses, %{red1 => s, red2 => s, blue1 => s, blue2 => s})

    {:noreply, socket}
  end

  def handle_info({:tracking, team}, socket) do
    socket =
      socket
      |> assign(:statuses, Map.put(socket.assigns[:statuses], team, "tracking"))

    {:noreply, socket}
  end

  def handle_info({:problem, team}, socket) do
    socket =
      socket
      |> assign(:statuses, Map.put(socket.assigns[:statuses], team, "problem"))

    {:noreply, socket}
  end
end
