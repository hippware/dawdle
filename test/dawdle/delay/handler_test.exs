defmodule Dawdle.Delay.HandlerTest do
  use ExUnit.Case, async: false

  import Dawdle.TestHelper

  alias Dawdle.Delay.Handler, as: DelayHandler

  setup_all do
    Dawdle.start_pollers()
  end

  setup do
    clear_all_handlers()

    :ok = DelayHandler.register()

    :ok
  end

  test "delayed function call" do
    pid = self()

    Dawdle.call_after(1, fn -> send(pid, :handled) end,
      delay_unit: :milliseconds
    )

    assert_receive :handled
  end

  test "long delayed function call" do
    pid = self()

    Dawdle.call_after(30 * 60, fn -> send(pid, :handled) end,
      delay_unit: :milliseconds
    )

    assert_receive :handled, 2_000
  end

  test "dispatched function call" do
    pid = self()

    Dawdle.call(fn -> send(pid, :handled) end)

    assert_receive :handled
  end
end
