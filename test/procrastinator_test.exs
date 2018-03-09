defmodule ProcrastinatorTest do
  use ExUnit.Case
  doctest Procrastinator

  test "greets the world" do
    assert Procrastinator.hello() == :world
  end
end
