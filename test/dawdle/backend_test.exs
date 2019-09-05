defmodule Dawdle.BackendTest do
  use ExUnit.Case, async: false

  # When the test suite is run against the local backend (the default), then
  # this test serves as a sanity check that the local backend is behaving as
  # expected. It also serves to validate the SQS backend when the test suite is
  # run against SQS.

  alias Dawdle.Backend
  alias Faker.Lorem

  setup_all do
    Dawdle.stop_pollers()
  end

  setup do
    {:ok, backend: Backend.new()}
  end

  test "basic send and receive", %{backend: backend} do
    message = Lorem.sentence()

    assert :ok = backend.send(message)
    assert {:ok, messages} = backend.recv()

    for msg <- messages do
      assert :ok = backend.delete(msg)
    end

    assert Enum.any?(messages, fn %{body: msg} -> msg == message end)
  end

  test "receive multiple messages", %{backend: backend} do
    message1 = Lorem.sentence()
    message2 = Lorem.sentence()

    assert :ok = backend.send(message1)
    assert :ok = backend.send(message2)

    receive_messages(backend, message1, message2)
  end

  defp receive_messages(backend, m1, m2, acc \\ [], count \\ 1)

  defp receive_messages(_, _, _, _, 5) do
    flunk("Did not receive messages after 5 tries")
  end

  defp receive_messages(backend, m1, m2, acc, count) do
    {:ok, messages} = backend.recv()

    for msg <- messages do
      assert :ok = backend.delete(msg)
    end

    msgs = acc ++ messages

    if length(msgs) >= 2 &&
         Enum.any?(msgs, fn %{body: msg} -> msg == m1 end) &&
         Enum.any?(msgs, fn %{body: msg} -> msg == m2 end) do
      :ok
    else
      receive_messages(backend, m1, m2, msgs, count + 1)
    end
  end

  test "send delayed message", %{backend: backend} do
    message = Lorem.sentence()

    assert :ok = backend.send_after(message, 1)

    Process.sleep(10)

    assert {:ok, messages} = backend.recv()

    for msg <- messages do
      assert :ok = backend.delete(msg)
    end

    assert Enum.any?(messages, fn %{body: msg} -> msg == message end)
  end
end
