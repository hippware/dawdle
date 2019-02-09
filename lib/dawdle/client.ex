defmodule TestMsg do
  defstruct [:foo, :bar, :baz]
end

defmodule Dawdle.Client do
  @moduledoc """
  The client for the DawdleDB - entities interested in queue events
  should subscribe to this process.
  """

  defmodule State do
    defstruct [:subscribers, :backend]
  end

  use GenServer

  alias Dawdle.Backend
  alias Dawdle.MessageEncoder.Term, as: MessageEncoder
  alias Dawdle.Poller

  require Logger

  def start_link, do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc false
  def recv(events), do: GenServer.cast(__MODULE__, {:recv, events})

  def signal(object) do
    GenServer.call(__MODULE__, {:signal, object})
  end

  def subscribe(object, fun) do
    GenServer.call(__MODULE__, {:subscribe, object, fun})
  end

  def unsubscribe(ref) do
    GenServer.call(__MODULE__, {:unsubscribe, ref})
  end

  def clear_all_subscriptions do
    GenServer.call(__MODULE__, :clear_all_subscriptions)
  end

  def init(_) do
    backend = Backend.new()

    Poller.start_link(backend, __MODULE__)

    {:ok, %State{backend: backend, subscribers: %{}}}
  end

  def handle_cast({:recv, events}, state) do
    Enum.each(events, &forward_event(&1, state))
    {:noreply, state}
  end

  def handle_call({:signal, event}, _from, state) do
    message = MessageEncoder.encode(event)

    state.backend.send([message])

    {:reply, :ok, state}
  end

  def handle_call({:subscribe, object, fun}, _from, state) do
    current = Map.get(state.subscribers, object, MapSet.new())
    ref = make_ref()

    new_subscribers =
      Map.put(state.subscribers, object, MapSet.put(current, {fun, ref}))

    {:reply, {:ok, ref}, %State{state | subscribers: new_subscribers}}
  end

  def handle_call({:unsubscribe, ref}, _from, state) do
    new_subscribers =
      state.subscribers
      |> Enum.map(&delete_ref(&1, ref))
      |> Map.new()

    {:reply, :ok, %State{state | subscribers: new_subscribers}}
  end

  def handle_call(:clear_all_subscriptions, _from, state) do
    {:reply, :ok, %State{state | subscribers: %{}}}
  end

  defp forward_event(message, state) do
    %object{} = event = MessageEncoder.decode(message)

    state.subscribers
    |> Map.get(object, [])
    |> Enum.each(fn {fun, _ref} -> fun.(event) end)
  rescue
    error ->
      Logger.error(
        "Dawdle event handler crash: #{inspect(error)}" #,
        # %{event: inspect(json_event), error: inspect(error)},
        # self() |> Process.info(:current_stacktrace) |> elem(1)
      )
  end

  defp delete_ref({key, val}, ref) do
    to_delete = Enum.find(val, fn v -> elem(v, 1) == ref end)
    {key, MapSet.delete(val, to_delete)}
  end
end
