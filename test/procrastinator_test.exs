defmodule ProcrastinatorTest do
  use ExUnit.Case, async: false

  setup do
    self = self()
    Procrastinator.start_link(&callback(self, &1))
    :ok
  end

  @payload "test message"
  test "send message with no delay" do
    Procrastinator.send(@payload, 0)
    assert_receive @payload
  end

  test "send message with 1s delay" do
    Procrastinator.send(@payload, 1000)
    refute_receive _, 800
    assert_receive @payload, 300
  end

  @intervals [1000, 5000, 10000]
  test "send 10 messages with various delays" do
    @intervals
    |> Enum.map(&List.duplicate(&1, 10))
    |> List.flatten()
    |> Enum.shuffle()
    |> Enum.each(&Procrastinator.send(&1, &1))

    :timer.send_after(800, :none)
    :timer.send_after(1200, :receive)
    :timer.send_after(4800, :none)
    :timer.send_after(5200, :receive)
    :timer.send_after(9800, :none)
    :timer.send_after(10200, :receive)

    assert_receive :none, 1000
    refute_receive _, 0
    assert_receive :receive, 5000
    Enum.each(1..10, fn _ -> assert_received 1000 end)

    assert_receive :none, 4000
    refute_receive _, 0
    assert_receive :receive, 5000
    Enum.each(1..10, fn _ -> assert_received 5000 end)

    assert_receive :none, 5000
    refute_receive _, 0
    assert_receive :receive, 5000
    Enum.each(1..10, fn _ -> assert_received 10000 end)
  end

  def callback(pid, payload), do: send(pid, payload)
end
