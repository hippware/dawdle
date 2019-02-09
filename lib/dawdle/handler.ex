defmodule Dawdle.Handler do
  @moduledoc """
  Defines a handler for queued events.
  """

  defmacro __using__(opts) do
    quote do
      alias Dawdle.Client

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
