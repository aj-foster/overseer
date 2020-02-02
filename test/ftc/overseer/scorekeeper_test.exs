defmodule FTC.Overseer.ScorekeeperTest do
  use ExUnit.Case, async: false

  alias FTC.Overseer.Scorekeeper

  describe "get_active_match/0" do
    test "retrieves a qualification match in progress" do
      assert {:ok, match} = Scorekeeper.get_active_match()
      assert %{name: "Q2", teams: [7, 8, 5, 6]} = match
    end

    test "retrieves an elimination match in progress" do
      old_code = Application.get_env(:overseer, :scoring_event)
      Application.put_env(:overseer, :scoring_event, "elim_test")

      assert {:ok, match} = Scorekeeper.get_active_match()
      assert %{name: "SF1-1", teams: [3, -1, 1, 2]} = match

      Application.put_env(:overseer, :scoring_event, old_code)
    end
  end
end
