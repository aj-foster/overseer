defmodule FTC.Overseer.Scorekeeper.WebsocketTest do
  use ExUnit.Case

  alias FTC.Overseer.Scorekeeper.{MockSocket, Websocket}

  describe "start_link/1" do
    test "connects to the stream endpoint" do
      assert {:ok, _pid} = Websocket.start_link(name: FTC.Overseer.Scorekeeper.WebsocketTest)
    end
  end

  describe "handle_frame/2" do
    test "handles match start message" do
      event = "handle_frame_2_handles_match_start_message"

      test_pid = self()
      start_match = fn _name -> send(test_pid, :start_match) end

      Websocket.start_link(
        name: FTC.Overseer.Scorekeeper.WebsocketTest,
        event: event,
        on_start: start_match
      )

      MockSocket.match_start(event)
      assert_receive :start_match
    end
  end
end
