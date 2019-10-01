defmodule Dawdle.Backend.SQSTest do
  use ExUnit.Case, async: false

  alias Dawdle.Backend.SQS
  alias Faker.Lorem

  setup_all do
    Dawdle.stop_pollers()
  end

  setup do
    {:ok, queue: SQS.queue()}
  end

  test "basic send and receive" do
    message = Lorem.sentence()

    assert :ok = SQS.send(message)
    assert {:ok, messages} = SQS.recv()

    for msg <- messages do
      assert :ok = SQS.delete(msg)
    end

    assert Enum.any?(messages, fn %{body: msg} -> msg == message end)
  end

  test "receive multiple messages" do
    message1 = Lorem.sentence()
    message2 = Lorem.sentence()

    assert :ok = SQS.send(message1)
    assert :ok = SQS.send(message2)

    receive_messages(message1, message2)
  end

  defp receive_messages(m1, m2, acc \\ [], count \\ 1)

  defp receive_messages(_, _, _, 5) do
    flunk("Did not receive messages after 5 tries")
  end

  defp receive_messages(m1, m2, acc, count) do
    {:ok, messages} = SQS.recv()

    for msg <- messages do
      assert :ok = SQS.delete(msg)
    end

    msgs = acc ++ messages

    if length(msgs) >= 2 &&
         Enum.any?(msgs, fn %{body: msg} -> msg == m1 end) &&
         Enum.any?(msgs, fn %{body: msg} -> msg == m2 end) do
      :ok
    else
      receive_messages(m1, m2, msgs, count + 1)
    end
  end

  test "send delayed message" do
    message = Lorem.sentence()

    assert :ok = SQS.send_after(message, 1)

    Process.sleep(10)

    assert {:ok, messages} = SQS.recv()

    for msg <- messages do
      assert :ok = SQS.delete(msg)
    end

    assert Enum.any?(messages, fn %{body: msg} -> msg == message end)
  end
end
