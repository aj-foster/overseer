defmodule FTC.Overseer.Scorekeeper.MockServer do
  @moduledoc """
  Provides a mock server for the scorekeeping API in testing and development.
  """
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

# {:ok,
#  %HTTPoison.Response{
#    body: "{\"matches\":[{\"matchName\":\"Q1\",\"matchNumber\":1,\"field\":1,\"red\":{\"team1\":5937,\"team2\":5070,\"isTeam1Surrogate\":false,\"isTeam2Surrogate\":false},\"blue\":{\"team1\":9779,\"team2\":6327,\"isTeam1Surrogate\":false,\"isTeam2Surrogate\":false},
#  \"finished\":false,\"matchState\":\"REVIEW\",\"time\":1576292978551},{\"matchName\":\"Q2\",\"matchNumber\":2,\"field\":2,\"red\":{\"team1\":15067,\"team2\":16733,\"isTeam1Surrogate\":false,\"isTeam2Surrogate\":false},\"blue\":{\"team1\":17340,\"team2\":17613,\"isTeam1Surrogate\":false,\"isTeam2Surrogate\":false},\"finished\":false,\"matchState\":\"AUTO\",\"time\":1576292978551}]}",
#    headers: [
#      {"Date", "Sat, 14 Dec 2019 03:45:38 GMT"},
#      {"Set-Cookie",
#       "JSESSIONID=node0uvfh4rj0nyhjni9rhi4hz9ax16.node0;Path=/api"},
#      {"Expires", "Thu, 01 Jan 1970 00:00:00 GMT"},
#      {"Content-Type", "application/json"},
#      {"Access-Control-Allow-Origin", "*"},
#      {"Access-Control-Allow-Method", "GET"},
#      {"Transfer-Encoding", "chunked"},
#      {"Server", "Jetty(9.4.18.v20190429)"}
#    ],
#    request: %HTTPoison.Request{
#      body: "",
#      headers: [],
#      method: :get,
#      options: [],
#      params: %{},
#      url: "http://10.10.10.10:8382/api/v1/events/test_01/matches/active/"
#    },
#    request_url: "http://10.10.10.10:8382/api/v1/events/test_01/matches/active/",
#    status_code: 200
#  }}
