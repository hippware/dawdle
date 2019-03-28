# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule DawdleTest do
  use ExUnit.Case

  import Eventually

  defmodule TestEvent do
    defstruct [:pid]
  end

  defmodule TestEvent2 do
    defstruct [:foo, :bar]
  end

  defmodule TestHandler do
    @moduledoc false

    use Dawdle.Handler

    def handle_event(%TestEvent{pid: pid}), do: send(pid, :handled)
  end

  defmodule TestRehandler do
    @moduledoc false

    use Dawdle.Handler

    def handle_event(%TestEvent{pid: pid}), do: send(pid, :rehandled)
  end

  defmodule CrashyTestHandler do
    @moduledoc false

    use Dawdle.Handler

    def handle_event(_), do: raise RuntimeError
  end

  defmodule OnlyTestHandler do
    @moduledoc false

    use Dawdle.Handler, only: [TestEvent]

    def handle_event(_), do: :ok
  end

  defmodule ExceptTestHandler do
    @moduledoc false

    use Dawdle.Handler, except: [TestEvent2]

    def handle_event(_), do: :ok
  end

  setup_all do
    Dawdle.start_pollers()
  end

  setup do
    Dawdle.Client.clear_all_handlers()

    :ok = TestHandler.register()

    :ok
  end

  describe "handler registration" do
    test "should register the handler with the Client" do
      assert Dawdle.handler_count() == 1
    end

    test "should register multiple handlers with the Client" do
      assert :ok = TestRehandler.register()

      assert Dawdle.handler_count() == 2
    end

    test "should replace handlers on duplicate registrations" do
      assert :ok = TestHandler.register()

      assert Dawdle.handler_count() == 1
    end

    test "should respect :only flag" do
      assert :ok = OnlyTestHandler.register()

      assert Dawdle.handler_count() == 2
      assert Dawdle.handler_count(TestEvent) == 2
      assert Dawdle.handler_count(TestEvent2) == 1
    end

    test "should respect :except flag" do
      assert :ok = ExceptTestHandler.register()

      assert Dawdle.handler_count() == 2
      assert Dawdle.handler_count(TestEvent) == 2
      assert Dawdle.handler_count(TestEvent2) == 1
    end

    test "should error on bad handler" do
      assert {:error, :module_not_handler} =
        Dawdle.register_handler(__MODULE__)

      assert {:error, :module_not_handler} =
        Dawdle.register_handler(:bad)
    end
  end

  describe "auto handler registration" do
    test "should register all known handlers" do
      :ok = Dawdle.register_all_handlers()

      assert_eventually Dawdle.handler_count() == 5
    end
  end

  describe "handler deregistration" do
    test "should remove the handler" do
      assert :ok = TestHandler.unregister()
      assert Dawdle.handler_count() == 0
    end

    test "should ignore unknown handlers" do
      assert :ok = TestRehandler.unregister()
      assert Dawdle.handler_count() == 1
    end
  end

  describe "event signaling" do
    test "should send event to a single handler" do
      t = %TestEvent{pid: self()}

      :ok = Dawdle.signal(t)

      assert_receive :handled, 25_000
    end

    test "should send batched events to a single handler" do
      t = %TestEvent{pid: self()}

      :ok = Dawdle.signal([t, t, t])

      assert_receive :handled, 25_000
      assert_receive :handled, 25_000
      assert_receive :handled, 25_000
    end

    test "should send event to mulitple handlers" do
      TestRehandler.register()

      t = %TestEvent{pid: self()}

      :ok = Dawdle.signal(t)

      assert_receive :handled, 25_000
      assert_receive :rehandled, 25_000
    end

    test "should behave when a handler crashes" do
      CrashyTestHandler.register()

      t = %TestEvent{pid: self()}

      :ok = Dawdle.signal(t)

      assert_receive :handled, 25_000
    end

    test "should delay event handling" do
      t = %TestEvent{pid: self()}

      :ok = Dawdle.signal(t, delay: 1)

      assert_receive :handled, 25_000
    end
  end
end
