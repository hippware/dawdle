defmodule DawdleTest do
  use ExUnit.Case

  setup_all do
    {:ok, _pid} = Dawdle.start_link(&callback(&1))

    :ok
  end

  setup do
    Process.register(self(), :message_target)
    :ok
  end

  @payload "0s"
  test "send message with no delay" do
    Dawdle.send(@payload, 0)
    assert_receive @payload, 500
  end

  @payload "1s"
  test "send message with 1s delay" do
    Dawdle.send(@payload, 1_000)
    refute_receive _, 800
    assert_receive @payload, 400
  end

  @intervals [1_000, 5_000, 10_000]
  test "send 5 messages with various delays" do
    @intervals
    |> Enum.map(&List.duplicate(&1, 5))
    |> List.flatten()
    |> Enum.shuffle()
    |> Enum.each(&Dawdle.send(&1, &1))

    Enum.each([500, 4_000, 9_000], &:erlang.send_after(&1, self(), :none))
    Enum.each([1_200, 6_000, 11_000], &:erlang.send_after(&1, self(), :receive))

    Enum.each(@intervals, fn i ->
        assert_receive :none, 20_000
        refute_received _
        assert_receive :receive, 20_000
        Enum.each(1..5, fn _ -> assert_received ^i end)
      end)
  end

  def callback(payload), do: send(:message_target, payload)
end
