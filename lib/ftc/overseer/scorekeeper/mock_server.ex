defmodule FTC.Overseer.Scorekeeper.MockServer do
  @moduledoc """
  Provides a mock server for the scorekeeping API in testing and development.
  """
  use Phoenix.Endpoint, otp_app: :overseer

  socket "/api/v2/stream", FTC.Overseer.Scorekeeper.MockSocket,
    websocket: [path: "/", timeout: :infinity],
    longpoll: false

  plug FTC.Overseer.Scorekeeper.MockRouter
end

defmodule FTC.Overseer.Scorekeeper.MockRouter do
  use Plug.Router

  alias Plug.Conn

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  get "/" do
    Conn.send_resp(conn, 200, "This is a mock Live Scoring API server")
  end

  get "/api/v1/events/:event_code/matches/active/" do
    time = :os.system_time(:millisecond)

    response =
      Jason.encode!(%{
        matches: [
          %{
            matchName: "Q1",
            matchNumber: 1,
            field: 1,
            red: %{team1: 1, team2: 2, isTeam1Surrogate: false, isTeam2Surrogate: false},
            blue: %{team1: 3, team2: 4, isTeam1Surrogate: false, isTeam2Surrogate: false},
            finished: false,
            matchState: "REVIEW",
            time: time
          },
          %{
            matchName: "Q2",
            matchNumber: 2,
            field: 2,
            red: %{team1: 5, team2: 6, isTeam1Surrogate: false, isTeam2Surrogate: false},
            blue: %{team1: 7, team2: 8, isTeam1Surrogate: false, isTeam2Surrogate: false},
            finished: false,
            matchState: "AUTO",
            time: time
          }
        ]
      })

    Conn.send_resp(conn, 200, response)
  end

  match _ do
    Conn.send_resp(conn, 404, "Route not defined")
  end
end
