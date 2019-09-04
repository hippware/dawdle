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

    assert :ok = backend.send([message])
    assert {:ok, messages} = backend.recv()
    assert :ok = backend.delete(messages)

    assert Enum.any?(messages, fn %{body: msg} -> msg == message end)
  end

  test "send multiple messages", %{backend: backend} do
    message1 = Lorem.sentence()
    message2 = Lorem.sentence()

    assert :ok = backend.send([message1, message2])
    assert {:ok, messages} = backend.recv()
    assert :ok = backend.delete(messages)

    assert length(messages) >= 2

    assert Enum.any?(messages, fn %{body: msg} -> msg == message1 end)
    assert Enum.any?(messages, fn %{body: msg} -> msg == message2 end)
  end

  test "send delayed message", %{backend: backend} do
    message = Lorem.sentence()

    assert :ok = backend.send_after(message, 1)

    Process.sleep(10)

    assert {:ok, messages} = backend.recv()
    assert :ok = backend.delete(messages)

    assert Enum.any?(messages, fn %{body: msg} -> msg == message end)
  end
end
