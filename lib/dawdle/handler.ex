defmodule Dawdle.Handler do
  @moduledoc """
  Defines a handler for queued events.

  To define an event handler, `use Dawdle.Handler` and provide a list of event
  types (structs) that you wish to handle. Then, override the callback
  `c:handle_event/1`.

  ## Examples

  ```
  defmodule MyApp.TestEvent do
    defstruct :foo, :bar
  end

  defmodule MyApp.TestEventHandler do
    use Dawdle.Handler, types: [MyApp.TestEvent]

    alias MyApp.TestEvent

    def handle_event(%TestEvent{foo: 1}) do
      # Do something...
    end

    def handle_event(%TestEvent{bar: 2}) do
      # Do something else...
    end

    def handle_event(%TestEvent{}) do
      # Default case
    end
  end
  ```
  """

  @doc """
  This function is called when Dawdle pulls an event of the appropriate type
  from the queue.

  It will only be called with events specified in the
  `use Dawdle.Handler` statement. The function is executed for its side effects
  and the return value is ignored.
  """
  @callback handle_event(event :: Dawdle.event()) :: any()

  defmacro __using__(opts) do
    quote do
      alias Dawdle.Client

      @behaviour Dawdle.Handler

      def register do
        Enum.each(unquote(opts[:types]), fn t ->
          Client.subscribe(t, &handle_event/1)
        end)
      end

      @spec handle_event(struct()) :: no_return()
      def handle_event(_event) do
        raise UndefinedFunctionError,
              "#{inspect(__MODULE__)} handle_event/1 not defined"
      end

      defoverridable handle_event: 1
    end
  end
end
