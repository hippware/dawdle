defmodule Dawdle.ClientTest do
  use ExUnit.Case

  alias Dawdle.Client

  defmodule TestEvent do
    defstruct [:pid]
  end

  defmodule TestHandler do
    use Dawdle.Handler, types: [TestEvent]

    def handle_event(%TestEvent{} = event) do
      send(event.pid, :handled)
      :ok
    end
  end

  setup_all do
    {:ok, _pid} = Client.start_link()

    TestHandler.register()

    :ok
  end

  test "basic event handler" do
    t = %TestEvent{pid: self()}

    Client.signal(t)

    assert_receive :handled
  end
end
