defmodule FTC.Display.SettingsController do
  use FTC.Display, :controller

  alias FTC.Overseer.Scorekeeper

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    scoring_host = Scorekeeper.get_api_host()
    event_code = Scorekeeper.get_event_code()

    render(conn, "index.html", scoring_host: scoring_host, event_code: event_code)
  end

  @spec update(Plug.Conn.t(), any) :: Plug.Conn.t()
  def update(conn, %{"scoring_host" => scoring_host, "event_code" => event_code}) do
    with :ok <- Scorekeeper.set_api_host(scoring_host),
         :ok <- Scorekeeper.set_event_code(event_code) do
      scoring_host = Scorekeeper.get_api_host()
      event_code = Scorekeeper.get_event_code()
      message = "Settings updated successfully"

      render(conn, "index.html",
        scoring_host: scoring_host,
        event_code: event_code,
        message: message
      )
    else
      {:error, error} ->
        message = "An error occurred while updating the scoring host: #{error}"

        render(conn, "index.html",
          scoring_host: scoring_host,
          event_code: event_code,
          message: message
        )
    end
  end
end
