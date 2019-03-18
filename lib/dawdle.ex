defmodule Dawdle do
  @moduledoc """
  API for the Dawdle messaging system.
  """

  @type duration :: non_neg_integer()
  @type event :: struct()
  @type handler :: module()

  @doc """
  Signals an event.

  The event is encoded and enqueued and will be processed by a handler running
  on a node running the Dawdle listener. See `Dawdle.Handler` for information
  on creating event handlers.

  Use the `:delay` option to delay the signaling of the event.

  Returns `:ok` when the event is successfully enqueued. Otherwise, returns
  an error tuple.

  ## Examples

  ```
  defmodule MyApp.TestEvent do
    defstruct :foo, :bar
  end

  Dawdle.signal(%MyApp.TestEvent{foo: 1, bar: 2})

  Dawdle.signal(%MyApp.TestEvent{foo: 1, bar: 2}, delay: 5)
  ```
  """
  @spec signal(event() | [event()], Keyword.t()) :: :ok | {:error, term()}
  defdelegate signal(event, opts \\ []), to: Dawdle.Client

  @doc """
  Registers all known event handlers.

  Dawdle searches through all loaded modules for any that implement the
  `Dawdle.Handler` behaviour and registers them. This is automatically called
  when the `:dawdle` application starts.
  """
  @spec register_all_handlers() :: :ok
  defdelegate register_all_handlers, to: Dawdle.Client

  @doc """
  Registers an event handler.

  After calling this function, the next time the specified event occurs, then
  the handler function will be called with data from that event.
  """
  @spec register_handler(handler(), Keyword.t()) :: :ok | {:error, term()}
  defdelegate register_handler(handler, opts \\ []), to: Dawdle.Client

  @doc """
  Unregisters an event handler.
  """
  @spec unregister_handler(handler()) :: :ok
  defdelegate unregister_handler(handler), to: Dawdle.Client

  @doc """
  Returns the total number of subscribers.
  """
  @spec handler_count :: non_neg_integer()
  defdelegate handler_count, to: Dawdle.Client

  @doc """
  Returns the number of subscribers to a specific event.
  """
  @spec handler_count(event()) :: non_neg_integer()
  defdelegate handler_count(event), to: Dawdle.Client
end
