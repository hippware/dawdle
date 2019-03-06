defmodule Dawdle.Client do
  @moduledoc """
  Manages subscriptions and polling of the event queues.

  Note that it is better to use the API provided by the `Dawdle` and
  `Dawdle.Handler` modules than the lower-level API described here.
  """

  defmodule State do
    @moduledoc false
    defstruct [:subscribers, :backend]
  end

  use GenServer

  alias Dawdle.Backend
  alias Dawdle.MessageEncoder.Term, as: MessageEncoder
  alias Dawdle.Poller.Supervisor, as: PollerSup

  require Logger

  @doc """
  Signals an event.

  The event data is encoded and enqueued. It will then be dequeued and passed
  to an event handler on a node with the listener running.
  """
  @spec signal(Dawdle.event()) :: :ok | {:error, term()}
  def signal(event) do
    GenServer.call(__MODULE__, {:signal, event})
  end

  @doc """
  Signals an event with a delay.

  See `signal/1`.
  """
  @spec signal(Dawdle.event(), Dawdle.duration()) :: :ok | {:error, term()}
  def signal(event, delay) do
    GenServer.call(__MODULE__, {:signal, event, delay})
  end

  @doc """
  Subscribes to an event.

  After calling this function, the next time the specified event occurs, then
  the handler function will be called with data from that event.

  The return value is used to unsubscribe.
  """
  @spec subscribe(Dawdle.event(), Dawdle.handler()) :: {:ok, reference()}
  def subscribe(event, fun) do
    GenServer.call(__MODULE__, {:subscribe, event, fun})
  end

  @doc """
  Unsubscribes from an event.

  The `ref` parameter is taken from the return value of `subscribe/2`.
  """
  @spec unsubscribe(reference()) :: :ok
  def unsubscribe(ref) do
    GenServer.call(__MODULE__, {:unsubscribe, ref})
  end

  @doc """
  Returns the total number of subscribers.
  """
  @spec subscriber_count :: non_neg_integer()
  def subscriber_count do
    GenServer.call(__MODULE__, :subscriber_count)
  end

  @doc """
  Returns the number of subscribers to a specific event.
  """
  @spec subscriber_count(Dawdle.event()) :: non_neg_integer()
  def subscriber_count(event) do
    GenServer.call(__MODULE__, {:subscriber_count, event})
  end

  # These functions are used for testing and not considered part of the API.
  # Their use in a production application is dangerous.

  @doc false
  def clear_all_subscriptions do
    GenServer.call(__MODULE__, :clear_all_subscriptions)
  end

  @doc false
  def stop_listeners do
    PollerSup
    |> Supervisor.which_children()
    |> Enum.each(fn {id, _, _, _} ->
      Supervisor.terminate_child(PollerSup, id)
      Supervisor.delete_child(PollerSup, id)
    end)

    :ok
  end

  # This function is called by the poller when new events are ready
  @doc false
  def recv(events), do: GenServer.cast(__MODULE__, {:recv, events})

  # GenServer implementation

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @impl true
  def init(_) do
    backend = Backend.new()
    state = %State{backend: backend, subscribers: %{}}

    {:ok, state, {:continue, true}}
  end

  @impl true
  def handle_continue(_, state) do
    if Confex.get_env(:dawdle, :start_listener) do
      PollerSup.start_pollers(state.backend, __MODULE__)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:recv, events}, state) do
    Enum.each(events, &forward_event(&1, state))
    {:noreply, state}
  end

  @impl true
  def handle_call({:signal, event}, _from, state) do
    message = MessageEncoder.encode(event)

    result = state.backend.send([message])

    {:reply, result, state}
  end

  @impl true
  def handle_call({:signal, event, delay}, _from, state) do
    message = MessageEncoder.encode(event)

    result = state.backend.send_after(message, delay)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:subscribe, object, fun}, _from, state) do
    current = Map.get(state.subscribers, object, MapSet.new())
    ref = make_ref()

    new_subscribers =
      Map.put(state.subscribers, object, MapSet.put(current, {fun, ref}))

    {:reply, {:ok, ref}, %State{state | subscribers: new_subscribers}}
  end

  @impl true
  def handle_call({:unsubscribe, ref}, _from, state) do
    new_subscribers =
      state.subscribers
      |> Enum.map(&delete_ref(&1, ref))
      |> Map.new()

    {:reply, :ok, %State{state | subscribers: new_subscribers}}
  end

  @impl true
  def handle_call(:subscriber_count, _from, state) do
    count =
      Enum.reduce(state.subscribers, 0, fn {_, x}, acc ->
        MapSet.size(x) + acc
      end)

    {:reply, count, state}
  end

  @impl true
  def handle_call({:subscriber_count, object}, _from, state) do
    subscribers = Map.get(state.subscribers, object, MapSet.new())

    {:reply, MapSet.size(subscribers), state}
  end

  @impl true
  def handle_call(:clear_all_subscriptions, _from, state) do
    {:reply, :ok, %State{state | subscribers: %{}}}
  end

  defp forward_event(message, state) do
    %object{} = event = MessageEncoder.decode(message)

    state.subscribers
    |> Map.get(object, [])
    |> Enum.each(fn {fun, _ref} -> call_handler(fun, event) end)
  end

  defp call_handler(fun, event) do
    Task.start(__MODULE__, :do_call_handler, [fun, event])
  end

  @doc false
  def do_call_handler(fun, event) do
    fun.(event)
  rescue
    error ->
      Logger.error("""
      Dawdle event handler crash:
        Event: #{inspect(event)}
        Error: #{inspect(error)}

        #{inspect(__STACKTRACE__)}
      """)
  end

  defp delete_ref({key, val}, ref) do
    to_delete = Enum.find(val, fn v -> elem(v, 1) == ref end)
    {key, MapSet.delete(val, to_delete)}
  end
end
