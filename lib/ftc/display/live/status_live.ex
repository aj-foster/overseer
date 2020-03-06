defmodule FTC.Display.StatusLive do
  use Phoenix.LiveView
  require Logger

  alias FTC.Overseer.Match

  def render(assigns) do
    Phoenix.View.render(FTC.Display.PageView, "index.html", assigns)
  end

  @spec mount(any, Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_, socket) do
    Phoenix.PubSub.subscribe(FTC.Display.PubSub, "status")

    case FTC.Overseer.get_match() do
      {:ok, %Match{} = match} ->
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

  @spec handle_info(
          {:start, any}
          | {:teams, [pos_integer()]}
          | :stop
          | :abort
          | {:problem, any}
          | {:tracking, any},
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}

  # Match started.
  def handle_info({:start, match_name}, socket) do
    socket =
      socket
      |> assign(:status, "In Progress")
      |> assign(:match, match_name)

    {:noreply, socket}
  end

  # Match ended.
  def handle_info(:stop, socket) do
    socket =
      socket
      |> assign(:status, "Finished")

    {:noreply, socket}
  end

  # Match aborted.
  def handle_info(:abort, socket) do
    socket =
      socket
      |> assign(:status, "Aborted")

    {:noreply, socket}
  end

  # Received information about which teams are playing.
  def handle_info({:teams, teams}, socket) do
    s = "searching"
    [red1, blue1, red2, blue2] = transpose_teams(teams)

    socket =
      socket
      |> assign(:teams, [red1, blue1, red2, blue2])
      |> assign(:statuses, %{red1 => s, red2 => s, blue1 => s, blue2 => s})

    {:noreply, socket}
  end

  # Tracking of a team has begun.
  def handle_info({:tracking, team}, socket) do
    statuses = Map.put(socket.assigns[:statuses], team, "tracking")
    socket = assign(socket, :statuses, statuses)

    {:noreply, socket}
  end

  # An issue with a team has been detected.
  def handle_info({:problem, team}, socket) do
    statuses = Map.put(socket.assigns[:statuses], team, "problem")
    socket = assign(socket, :statuses, statuses)

    {:noreply, socket}
  end

  # Reposition teams to appear similar to their physical orientation.
  defp transpose_teams([blue1, blue2, red1, red2]), do: [red1, blue1, red2, blue2]

  defp transpose_teams(teams) do
    Logger.error("Unable to reposition teams. Expected list of four, got: #{inspect(teams)}")
    []
  end
end
