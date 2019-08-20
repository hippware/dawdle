defmodule Dawdle.Backend.GenStageTest do
  use ExUnit.Case, async: false

  alias Dawdle.Backend.GenStage, as: Backend
  alias Dawdle.Backend.GenStage.Producer
  alias Dawdle.Backend.GenStageTest.Receiver
  alias Faker.Lorem

  setup_all do
    Receiver.start_link()

    GenStage.start_link(Producer, [], name: Producer.name())
    Dawdle.Poller.Supervisor.start_pollers(Backend, Receiver)

    :ok
  end

  setup do
    Receiver.set_target()

    :ok
  end

  describe "send/1" do
    test "sending a single message" do
      message = Lorem.sentence()

      :ok = Backend.send([message])

      assert_receive %{body: ^message}
      refute_receive _
    end

    test "accruing messages" do
      message1 = Lorem.sentence()
      message2 = Lorem.sentence()

      :ok = Backend.send([message1])
      :ok = Backend.send([message2])

      assert_receive %{body: ^message1}
      assert_receive %{body: ^message2}
      refute_receive _
    end

    test "sending multiple messages" do
      message1 = Lorem.sentence()
      message2 = Lorem.sentence()

      :ok = Backend.send([message1, message2])

      assert_receive %{body: ^message1}
      assert_receive %{body: ^message2}
      refute_receive _
    end
  end

  describe "send_after/2" do
    test "sending a delayed message" do
      message = Lorem.sentence()

      :ok = Backend.send_after(message, 10)

      refute_receive _, 5

      assert_receive %{body: ^message}
    end
  end

  defmodule Receiver do
    use GenServer

    def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

    def set_target(), do: GenServer.call(__MODULE__, {:set_target, self()})

    def recv(event, _queue), do: GenServer.call(__MODULE__, {:event, event})

    def init(_), do: {:ok, nil}

    def handle_call({:set_target, target}, _, _), do: {:reply, :ok, target}

    def handle_call({:event, event}, _, target) do
      send(target, event)
      {:reply, :ok, target}
    end
  end
end
