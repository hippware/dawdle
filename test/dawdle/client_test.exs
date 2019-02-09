defmodule Dawdle.ClientTest do
  use ExUnit.Case

  alias Dawdle.Client

  defmodule TestEvent do
    defstruct [:pid]
  end

  setup_all do
    {:ok, _pid} = Client.start_link()

    :ok
  end

  test "basic signal handling" do
    Client.subscribe(TestEvent, fn %TestEvent{pid: pid} -> send(pid, :handled) end)

    t = %TestEvent{pid: self()}

    Dawdle.signal(t)

    assert_receive :handled
  end

  test "handler crash" do
    Client.subscribe(TestEvent, fn _ -> raise RuntimeError end)

    t = %TestEvent{pid: self()}

    Dawdle.signal(t)

    # TODO validation?
  end

  test "multiple handlers" do
    # TODO
  end

  test "subscribe/2" do
    count = Client.subscriber_count(TestEvent)

    Client.subscribe(TestEvent, fn _ -> :ok end)

    assert Client.subscriber_count(TestEvent) == count + 1
  end

  test "unsubscribe/1" do
    {:ok, ref} = Client.subscribe(TestEvent, fn _ -> :ok end)
    count = Client.subscriber_count(TestEvent)

    Client.unsubscribe(ref)

    assert Client.subscriber_count(TestEvent) == count - 1
  end

  test "subscriber_count" do
    Client.subscribe(TestEvent, fn _ -> :ok end)

    assert Client.subscriber_count() == Client.subscriber_count(TestEvent)
  end

  test "clear_all_subscriptions" do
    Client.subscribe(TestEvent, fn _ -> :ok end)

    Client.clear_all_subscriptions()

    assert Client.subscriber_count() == 0
  end
end
