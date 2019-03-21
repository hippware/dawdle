defmodule Dawdle.Client do
  # Manages handler registration and polling of the event queues.

  @moduledoc false

  defmodule State do
    @moduledoc false
    defstruct handlers: [],
              backend: nil
  end

  use GenServer

  alias Dawdle.Backend
  alias Dawdle.MessageEncoder.Term, as: MessageEncoder
  alias Dawdle.Poller.Supervisor, as: PollerSup

  require Logger

  # These functions are delegated to here from the `Dawdle` module.
  # Their types and definitions are defined there.

  def signal(event, opts \\ []) do
    GenServer.call(__MODULE__, {:signal, event, opts})
  end

  def register_all_handlers do
    GenServer.call(__MODULE__, :register_all_handlers)
  end

  def register_handler(handler, options \\ []) do
    GenServer.call(__MODULE__, {:register_handler, handler, options})
  end

  def unregister_handler(handler) do
    GenServer.call(__MODULE__, {:unregister_handler, handler})
  end

  def handler_count do
    GenServer.call(__MODULE__, :handler_count)
  end

  def handler_count(event) do
    GenServer.call(__MODULE__, {:handler_count, event})
  end

  # This function is used for testing and not considered part of the API.
  # Its use in a production application is dangerous.
  @doc false
  def clear_all_handlers do
    GenServer.call(__MODULE__, :clear_all_handlers)
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
    state = %State{backend: backend, handlers: []}

    {:ok, state, {:continue, true}}
  end

  @impl true
  def handle_continue(_, state) do
    if Confex.get_env(:dawdle, :start_listener) do
      :ok = PollerSup.start_pollers(state.backend, __MODULE__)
      {:ok, _} = Task.start(&auto_register_handlers/0)
    end

    {:noreply, state}
  end

  defp auto_register_handlers do
    for {mod, _} <- :code.all_loaded() do
      mod
      |> handler?()
      |> maybe_register_handler(mod)
    end
  end

  defp maybe_register_handler(true, mod), do: mod.register()
  defp maybe_register_handler(false, _), do: :ok

  @impl true
  def handle_cast({:recv, events}, state) do
    Enum.each(events, &forward_event(&1, state))
    {:noreply, state}
  end

  @impl true
  def handle_call({:signal, events, _opts}, _from, state)
      when is_list(events) do
    messages = Enum.map(events, &MessageEncoder.encode/1)
    result = state.backend.send(messages)

    {:reply, result, state}
  end

  def handle_call({:signal, event, opts}, _from, state) do
    message = MessageEncoder.encode(event)
    delay = Keyword.get(opts, :delay, 0)

    result =
      if delay == 0 do
        state.backend.send([message])
      else
        state.backend.send_after(message, delay)
      end

    {:reply, result, state}
  end

  def handle_call(:register_all_handlers, _from, state) do
    {:ok, _} = Task.start(&auto_register_handlers/0)

    {:reply, :ok, state}
  end

  def handle_call({:register_handler, handler, options}, _from, state) do
    if handler?(handler) do
      options = Keyword.take(options, [:only, :except])
      handlers = List.keystore(state.handlers, handler, 0, {handler, options})

      {:reply, :ok, %State{state | handlers: handlers}}
    else
      {:reply, {:error, :module_not_handler}, state}
    end
  end

  def handle_call({:unregister_handler, handler}, _from, state) do
    handlers = List.keydelete(state.handlers, handler, 0)

    {:reply, :ok, %State{state | handlers: handlers}}
  end

  def handle_call(:handler_count, _from, state) do
    {:reply, Enum.count(state.handlers), state}
  end

  def handle_call({:handler_count, object}, _from, state) do
    count =
      state.handlers
      |> Enum.filter(fn {_, options} ->
        should_call_handler?(options, object)
      end)
      |> Enum.count()

    {:reply, count, state}
  end

  def handle_call(:clear_all_handlers, _from, state) do
    {:reply, :ok, %State{state | handlers: []}}
  end

  defp handler?(mod) do
    mod.module_info(:attributes)
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(Dawdle.Handler)
  rescue
    _ -> false
  end

  defp forward_event(message, state) do
    %object{} = event = MessageEncoder.decode(message)

    Enum.each(state.handlers, &maybe_call_handler(&1, object, event))
  end

  defp maybe_call_handler({handler, options}, object, event) do
    if should_call_handler?(options, object) do
      Task.start(__MODULE__, :do_call_handler, [handler, event])
    end
  end

  defp should_call_handler?([], _), do: true

  defp should_call_handler?(options, object) do
    except = Keyword.get(options, :except, [])
    only = Keyword.get(options, :only, [])

    !Enum.member?(except, object) && (only == [] || Enum.member?(only, object))
  end

  @doc false
  def do_call_handler(handler, event) do
    handler.handle_event(event)
  rescue
    error ->
      Logger.error("""
      Dawdle event handler crash:
        Event: #{inspect(event)}
        Error: #{inspect(error)}

        #{inspect(__STACKTRACE__, pretty: true)}
      """)
  end
end
