defmodule Dawdle.BackendTest do
  use ExUnit.Case

  # When the test suite is run against the local backend (the default), then
  # this test serves as a sanity check that the local backend is behaving as
  # expected. It also serves to validate the SQS backend when the test suite is
  # run against SQS.

  alias Dawdle.Backend

  setup_all do
    Application.stop(:dawdle)

    on_exit fn -> Application.start(:dawdle) end
  end

  setup do
    backend = Backend.new()

    backend.flush()

    # This is cheating a little bit to get the queue names
    message_queue = hd(backend.queues())
    delay_queue = hd(Enum.reverse(backend.queues()))

    {:ok,
      backend: backend,
      message_queue: message_queue,
      delay_queue: delay_queue}
  end

  test "basic send and receive", %{backend: backend, message_queue: q} do
    message = "this is a test"

    assert :ok = backend.send([message])
    assert {:ok, [%{body: message}] = msgs} = backend.recv(q)
    assert :ok = backend.delete(q, msgs)
  end

  test "send multiple messages", %{backend: backend, message_queue: q} do
    assert :ok = backend.send(["multi test 1", "multi test 2"])
    assert {:ok, messages} = backend.recv(q)
    assert :ok = backend.delete(q, messages)

    assert length(messages) == 2
  end

  test "send delayed message", %{backend: backend, delay_queue: q} do
    message = "this is a delayed test"

    assert :ok = backend.send_after(message, 1)
    assert {:ok, [%{body: message}] = msgs} = backend.recv(q)
    assert :ok = backend.delete(q, msgs)
  end
end
