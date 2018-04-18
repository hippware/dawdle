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
    refute_receive _, 500
    assert_receive @payload, 1000
  end

  @intervals [1000, 5000, 10000]
  test "send 10 messages with various delays" do
    {setup_time, _} = :timer.tc(fn ->
        @intervals
        |> Enum.map(&List.duplicate(&1, 10))
        |> List.flatten()
        |> Enum.shuffle()
        |> Enum.each(&Procrastinator.send(&1, &1))
    end)

    offset = div(setup_time, 1000)

    :timer.send_after(max(500 - offset, 0), :none)
    :timer.send_after(max(1500 - offset, 0), :receive)
    :timer.send_after(4500 - offset, :none)
    :timer.send_after(5500 - offset, :receive)
    :timer.send_after(9500 - offset, :none)
    :timer.send_after(10500 - offset, :receive)

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
