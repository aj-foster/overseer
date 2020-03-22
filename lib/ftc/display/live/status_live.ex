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
          |> populate_teams(match.name, match.teams)

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
  def handle_info({:populated, match, teams}, socket) do
    {:noreply, populate_teams(socket, match, teams)}
  end

  # Tracking of a team has begun.
  def handle_info({:found, team_number, channel}, socket) do
    team_info =
      Map.get(socket.assigns[:statuses], team_number, %{})
      |> Map.put(:channel, channel)
      |> Map.put_new(:status, "tracking")

    statuses = Map.put(socket.assigns[:statuses], team_number, team_info)
    socket = assign(socket, :statuses, statuses)

    {:noreply, socket}
  end

  # An issue with a team has been detected.
  def handle_info({:deauthenticated, team_number, total_count}, socket) do
    team_info =
      Map.get(socket.assigns[:statuses], team_number, %{})
      |> Map.put(:packets, total_count)
      |> Map.put(:status, "problem")

    statuses = Map.put(socket.assigns[:statuses], team_number, team_info)
    socket = assign(socket, :statuses, statuses)

    {:noreply, socket}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  # Assign team numbers and statuses.
  #
  @spec populate_teams(Socket.t(), String.t(), [pos_integer]) :: Socket.t()
  defp populate_teams(socket, match, teams) do
    Enum.reduce(teams, socket, fn team_number, socket ->
      team_info =
        case FTC.Overseer.get_team(match, team_number) do
          {:ok, %{packets: x} = team_info} when is_integer(x) and x > 0 ->
            Map.put(team_info, :status, "problem")

          {:ok, %{channel: x} = team_info} when is_integer(x) ->
            Map.put(team_info, :status, "tracking")

          {:ok, team_info} ->
            team_info

          {:error, :not_found} ->
            %{}
        end

      statuses =
        Map.get(socket.assigns, :statuses, %{})
        |> Map.put(team_number, team_info)

      assign(socket, :statuses, statuses)
    end)
    |> assign(:teams, transpose_teams(teams))
  end

  # Reposition teams to appear similar to their physical orientation.
  #
  @spec transpose_teams([pos_integer]) :: [pos_integer]
  defp transpose_teams([blue1, blue2, red1, red2]), do: [red1, blue1, red2, blue2]

  defp transpose_teams(teams) do
    Logger.error("Unable to reposition teams. Expected list of four, got: #{inspect(teams)}")
    []
  end
end
