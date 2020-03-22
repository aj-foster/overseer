defmodule FTC.Display.StatusLive do
  use Phoenix.LiveView
  require Logger

  alias Phoenix.LiveView.Socket
  alias FTC.Overseer.Event
  alias FTC.Overseer.Match.State

  def render(assigns) do
    Phoenix.View.render(FTC.Display.PageView, "index.html", assigns)
  end

  @spec mount(any, Socket.t()) :: {:ok, Socket.t()}
  def mount(_, socket) do
    :ok = Event.subscribe("match")
    :ok = Event.subscribe("team")

    case FTC.Overseer.get_match() do
      {:ok, %State{} = match} ->
        socket =
          socket
          |> assign(:status, "In Progress")
          |> assign(:match, match.name)
          |> assign(:teams, transpose_teams(match.teams))
          |> assign(:statuses, %{})

        {:ok, socket}

      {:error, _} ->
        socket =
          socket
          |> assign(:status, "Ready")
          |> assign(:match, "")
          |> assign(:teams, [0, 0, 0, 0])
          |> assign(:statuses, %{})

        {:ok, socket}
    end
  end

  @spec handle_info(Event.event(), Socket.t()) :: {:noreply, Socket.t()}

  # Match started.
  def handle_info({:started, match_name}, socket) do
    socket =
      socket
      |> assign(:status, "In Progress")
      |> assign(:match, match_name)

    {:noreply, socket}
  end

  # Match ended.
  def handle_info({:ended, _match_name}, socket) do
    socket =
      socket
      |> assign(:status, "Finished")

    {:noreply, socket}
  end

  # Match aborted.
  def handle_info({:aborted, _match_name}, socket) do
    socket =
      socket
      |> assign(:status, "Aborted")

    {:noreply, socket}
  end

  # Received information about which teams are playing.
  def handle_info({:populated, _match_name, teams}, socket) do
    s = "searching"
    [red1, blue1, red2, blue2] = transpose_teams(teams)

    socket =
      socket
      |> assign(:teams, [red1, blue1, red2, blue2])
      |> assign(:statuses, %{red1 => s, red2 => s, blue1 => s, blue2 => s})

    {:noreply, socket}
  end

  # Tracking of a team has begun.
  def handle_info({:found, team, _channel}, socket) do
    statuses = Map.put(socket.assigns[:statuses], team, "tracking")
    socket = assign(socket, :statuses, statuses)

    {:noreply, socket}
  end

  # An issue with a team has been detected.
  def handle_info({:deauthenticated, team, _total_count}, socket) do
    statuses = Map.put(socket.assigns[:statuses], team, "problem")
    socket = assign(socket, :statuses, statuses)

    {:noreply, socket}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  # Reposition teams to appear similar to their physical orientation.
  defp transpose_teams([blue1, blue2, red1, red2]), do: [red1, blue1, red2, blue2]

  defp transpose_teams(teams) do
    Logger.error("Unable to reposition teams. Expected list of four, got: #{inspect(teams)}")
    []
  end
end
