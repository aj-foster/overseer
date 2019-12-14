defmodule FTC.Overseer.ScorekeeperTest do
  use ExUnit.Case

  alias FTC.Overseer.Scorekeeper

  describe "get_active_match/0" do
    test "retrieves a qualification match in progress" do
      assert {:ok, match} = Scorekeeper.get_active_match()
      assert %{name: "Q2"} = match
    end
  end
end
