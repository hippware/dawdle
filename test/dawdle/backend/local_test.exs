defmodule Dawdle.Backend.LocalTest do
  use ExUnit.Case, async: false

  import Eventually

  alias Dawdle.Backend.Local
  alias Faker.Lorem

  setup_all do
    Dawdle.stop_pollers()
  end

  setup do
    [queue] = Local.queues()

    Local.flush()

    {:ok, queue: queue}
  end

  describe "send/1" do
    test "sending a single message" do
      message = Lorem.sentence()

      :ok = Local.send([message])

      assert Local.count() == 1
    end

    test "accruing messages" do
      message1 = Lorem.sentence()
      message2 = Lorem.sentence()

      :ok = Local.send([message1])
      :ok = Local.send([message2])

      assert Local.count() == 2
    end

    test "sending multiple messages" do
      message1 = Lorem.sentence()
      message2 = Lorem.sentence()

      :ok = Local.send([message1, message2])

      assert Local.count() == 2
    end
  end

  describe "send_after/1" do
    test "sending a delayed message" do
      message = Lorem.sentence()

      :ok = Local.send_after(message, 5)

      assert_eventually Local.count() == 1
    end
  end

  describe "recv/1" do
    test "receiving a message", %{queue: q} do
      message = Lorem.sentence()

      :ok = Local.send([message])

      assert {:ok, [message]} = Local.recv(q)
    end

    test "receiving multiple messages", %{queue: q} do
      message1 = Lorem.sentence()
      message2 = Lorem.sentence()

      :ok = Local.send([message1, message2])

      assert {:ok, [message1, message2]} = Local.recv(q)
    end

    test "receiving from an empty queue", %{queue: q} do
      message = Lorem.sentence()

      Task.start(fn ->
        assert {:ok, [message]} = Local.recv(q)
      end)

      Process.sleep(10)

      :ok = Local.send([message])
    end
  end
end
