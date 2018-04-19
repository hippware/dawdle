defmodule DawdleTest do
  use ExUnit.Case

  setup_all do
    {:ok, _pid} = Dawdle.start_link()

    :ok
  end

  @payload "0s"
  test "set timeout with no delay" do
    self = self()
    Dawdle.call_after(&send(self, &1), @payload, 0)
    assert_receive @payload, 500
  end

  @payload "1s"
  test "set timeout with 1s delay" do
    self = self()
    Dawdle.call_after(&send(self, &1), @payload, 1_000)
    refute_receive _, 800
    assert_receive @payload, 400
  end

  @intervals [1_000, 5_000, 10_000]
  test "set 5 timeouts with various delays" do
    self = self()
    callback = &send(self, &1)
    @intervals
    |> Enum.map(&List.duplicate(&1, 5))
    |> List.flatten()
    |> Enum.shuffle()
    |> Enum.each(&Dawdle.call_after(callback, &1, &1))

    Enum.each([500, 4_000, 9_000], &:erlang.send_after(&1, self(), :none))
    Enum.each([1_200, 6_000, 11_000], &:erlang.send_after(&1, self(), :receive))

    Enum.each(@intervals, fn i ->
        assert_receive :none, 20_000
        refute_received _
        assert_receive :receive, 20_000
        Enum.each(1..5, fn _ -> assert_received ^i end)
      end)
  end
end
