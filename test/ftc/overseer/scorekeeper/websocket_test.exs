defmodule FTC.Overseer.Scorekeeper.WebsocketTest do
  use ExUnit.Case

  alias FTC.Overseer.Event
  alias FTC.Overseer.Scorekeeper.{MockSocket, Websocket}

  describe "start_link/1" do
    test "connects to the stream endpoint" do
      assert {:ok, _pid} = Websocket.start_link(name: FTC.Overseer.Scorekeeper.WebsocketTest)
    end
  end

  describe "handle_frame/2" do
    test "handles match start message" do
      Event.subscribe("match")
      event = "handle_frame_2_handles_match_start_message"

      Websocket.start_link(
        name: FTC.Overseer.Scorekeeper.WebsocketTest,
        event: event
      )

      MockSocket.match_start(event)
      assert_receive {:started, _match_name}
    end

    test "handles match abort message" do
      Event.subscribe("match")
      event = "handle_frame_2_handles_match_abort_message"

      Websocket.start_link(
        name: FTC.Overseer.Scorekeeper.WebsocketTest,
        event: event
      )

      MockSocket.match_abort(event)
      assert_receive {:aborted, _match_name}
    end
  end
end
