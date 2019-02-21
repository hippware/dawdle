defmodule Dawdle.ClientTest do
  use ExUnit.Case

  alias Dawdle.Client

  defmodule TestEvent do
    defstruct [:pid]
  end

  setup do
    Client.clear_all_subscriptions()

    {:ok, ref} =
      Client.subscribe(
        TestEvent,
        fn %TestEvent{pid: pid} -> send(pid, :handled) end
      )

    {:ok, ref: ref}
  end

  test "basic signal handling" do
    t = %TestEvent{pid: self()}

    :ok = Dawdle.signal(t)

    assert_receive :handled
  end

  test "multiple handlers" do
    Client.subscribe(
      TestEvent,
      fn %TestEvent{pid: pid} -> send(pid, :rehandled) end
    )

    t = %TestEvent{pid: self()}

    :ok = Dawdle.signal(t)

    assert_receive :handled
    assert_receive :rehandled
  end

  test "handler crash" do
    Client.subscribe(TestEvent, fn _ -> raise RuntimeError end)

    t = %TestEvent{pid: self()}

    :ok = Dawdle.signal(t)

    assert_receive :handled
  end

  test "subscribe/2" do
    Client.subscribe(TestEvent, fn _ -> :ok end)

    assert Client.subscriber_count(TestEvent) == 2
  end

  test "unsubscribe/1", %{ref: ref} do
    Client.unsubscribe(ref)

    assert Client.subscriber_count(TestEvent) == 0
  end

  test "subscriber_count" do
    assert Client.subscriber_count() == Client.subscriber_count(TestEvent)
  end

  test "clear_all_subscriptions" do
    Client.clear_all_subscriptions()

    assert Client.subscriber_count() == 0
  end
end
