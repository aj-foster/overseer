defmodule FTC.OverseerTest do
  use ExUnit.Case
  doctest FTC.Overseer

  test "greets the world" do
    assert FTC.Overseer.hello() == :world
  end
end
