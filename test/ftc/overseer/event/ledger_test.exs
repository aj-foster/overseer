defmodule FTC.Overseer.Event.LedgerTest do
  use ExUnit.Case

  alias FTC.Overseer.Event.Ledger

  describe "Ledger" do
    test "stores data related to teams" do
      pid = GenServer.whereis(FTC.Overseer.Event.Ledger)
      match = "ledger_stores_data_related_to_teams"

      send(pid, {:started, match})
      send(pid, {:populated, match, [1, 2, 3, 4]})
      send(pid, {:found, 1, 1})
      send(pid, {:found, 3, 157})
      send(pid, {:deauthenticated, 3, 2})

      assert {:ok, %{channel: 1}} = Ledger.get_team(match, 1)
      assert {:ok, %{channel: 157, packets: 2}} = Ledger.get_team(match, 3)
    end

    test "handles match abort and restart" do
      pid = GenServer.whereis(FTC.Overseer.Event.Ledger)
      match = "ledger_stores_data_related_to_teams"

      send(pid, {:started, match})
      send(pid, {:populated, match, [1, 2, 3, 4]})
      send(pid, {:found, 1, 1})
      send(pid, {:aborted, match})
      send(pid, {:started, match})
      send(pid, {:populated, match, [1, 2, 3, 4]})
      send(pid, {:found, 1, 6})

      assert {:ok, %{channel: 6}} = Ledger.get_team(match, 1)
    end
  end
end
