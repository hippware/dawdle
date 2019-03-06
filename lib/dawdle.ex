defmodule Dawdle do
  @moduledoc """
  API for the Dawdle messaging system.
  """

  @type duration :: non_neg_integer()
  @type fun :: (() -> any())
  @type event :: struct()
  @type handler :: ((event()) -> any())

  @doc """
  Send a function to be executed.

  The function is encoded and enqueued and will be executed on a node running
  the Dawdle listener. Even if the listener is running on the current node,
  the function may still be executed on another node.

  The passed function is evaluated for its side effects and any return value
  is ignored.

  Returns `:ok` when the function is successfully enqueued. Otherwise, returns
  an error tuple.

  ## Examples

  ```
  iex> Dawdle.call(fn ->
  ...> # Do something expensive...
  ...> :ok
  ...> end)
  :ok
  ```
  """
  @spec call(fun()) :: :ok | {:error, term()}
  defdelegate call(fun), to: Dawdle.Delay.Handler

  @doc """
  Send a function to be executed after a delay.

  The function is encoded and enqueued and will be executed on a node running
  the Dawdle listener after the specified delay. Even if the listener is
  running on the current node, the function may still be executed on another
  node.

  The passed function is evaluated for its side effects and any return value
  is ignored.

  Returns `:ok` when the function is successfully enqueued. Otherwise, returns
  an error tuple.

  ## Examples

  ```
  iex> Dawdle.call_after(5, fn ->
  ...> # Do something later...
  ...> :ok
  ...> end)
  :ok
  ```
  """
  @spec call_after(duration(), fun()) :: :ok | {:error, term()}
  defdelegate call_after(delay, fun), to: Dawdle.Delay.Handler

  @doc """
  Signals an event.

  The event is encoded and enqueued and will be processed by a handler running
  on a node running the Dawdle listener. See `Dawdle.Handler` for information
  on creating event handlers.

  Returns `:ok` when the event is successfully enqueued. Otherwise, returns
  an error tuple.

  ## Examples

  ```
  defmodule MyApp.TestEvent do
    defstruct :foo, :bar
  end

  Dawdle.signal(%MyApp.TestEvent{foo: 1, bar: 2})
  ```
  """
  @spec signal(event()) :: :ok | {:error, term()}
  defdelegate signal(event), to: Dawdle.Client
end
