defmodule Dawdle.Delay.HandlerTest do
  use ExUnit.Case

  setup_all do
    Dawdle.Delay.Handler.register()
  end

  test "delayed function call" do
    pid = self()

    Dawdle.call_after(1, fn -> send(pid, :handled) end)

    assert_receive :handled
  end

  test "long delayed function call" do
    pid = self()

    Dawdle.call_after(30 * 60, fn -> send(pid, :handled) end)

    assert_receive :handled, 2_000
  end

  test "dispatched function call" do
    pid = self()

    Dawdle.call(fn -> send(pid, :handled) end)

    assert_receive :handled
  end
end
