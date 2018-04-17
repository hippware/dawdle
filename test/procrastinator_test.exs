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
    refute_receive @payload, 800
    assert_receive @payload, 300
  end

  def callback(pid, payload), do: send(pid, payload)
end
