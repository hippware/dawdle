defmodule Dawdle.Client do
  # Manages handler registration and polling of the event queues.

  @moduledoc false

  defmodule State do
    @moduledoc false
    defstruct handlers: [],
              backend: nil
  end

  use GenServer

  import Dawdle.Telemetry

  alias Dawdle.Backend
  alias Dawdle.MessageEncoder
  alias Dawdle.Poller.Supervisor, as: PollerSup

  require Logger

  # These functions are delegated to here from the `Dawdle` module.
  # Their types and definitions are defined there.

  @spec signal(Dawdle.event(), Keyword.t()) :: :ok | {:error, term()}
  def signal(event, opts \\ []) do
    GenServer.call(__MODULE__, {:signal, event, opts})
  end

  @spec signal_async(Dawdle.event(), Keyword.t()) :: {:ok, pid()}
  def signal_async(event, opts \\ []) do
    Task.start(fn ->
      signal(event, opts)
    end)
  end

  @spec register_all_handlers() :: :ok
  def register_all_handlers do
    auto_register_handlers()
  end

  @spec register_handler(Dawdle.handler(), Keyword.t()) ::
          :ok | {:error, term()}
  def register_handler(handler, options \\ []) do
    GenServer.call(__MODULE__, {:register_handler, handler, options})
  end

  @spec unregister_handler(Dawdle.handler()) :: :ok
  def unregister_handler(handler) do
    GenServer.call(__MODULE__, {:unregister_handler, handler})
  end

  @spec handler_count :: non_neg_integer()
  def handler_count do
    GenServer.call(__MODULE__, :handler_count)
  end

  @spec handler_count(Dawdle.event()) :: non_neg_integer()
  def handler_count(event) do
    GenServer.call(__MODULE__, {:handler_count, event})
  end

  @spec start_pollers :: :ok
  def start_pollers do
    :ok = GenServer.call(__MODULE__, :start_pollers)
    :ok = auto_register_handlers()
  end

  @spec stop_pollers :: :ok
  def stop_pollers do
    GenServer.call(__MODULE__, :stop_pollers)
  end

  # This function is used for testing and not considered part of the API.
  # Its use in a production application is dangerous.
  @doc false
  @spec clear_all_handlers :: :ok
  def clear_all_handlers do
    GenServer.call(__MODULE__, :clear_all_handlers)
  end

  # This function is called by the poller when new messages are ready
  @doc false
  @spec recv([binary()]) :: :ok
  def recv(messages),
    do: GenServer.cast(__MODULE__, {:recv, messages})

  # GenServer implementation

  @doc false
  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @impl true
  def init(_) do
    backend = Backend.new()
    state = %State{backend: backend, handlers: []}

    {:ok, state, {:continue, true}}
  end

  @impl true
  def handle_continue(_, state) do
    _ =
      if Confex.get_env(:dawdle, :start_pollers) do
        do_start_pollers(state.backend)
        Task.start(&auto_register_handlers/0)
      end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:recv, messages}, state) do
    timed_fun([:dawdle, :receive], %{}, %{count: length(messages)}, fn ->
      decode_and_forward_events(messages, state)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:signal, event, opts}, _from, state) do
    result =
      timed_fun(
        [:dawdle, :signal],
        %{backend: state.backend, options: opts},
        %{count: 1},
        fn ->
          if opts[:direct] do
            forward_event(event, state.handlers)
          else
            {:ok, message} = MessageEncoder.encode(event)
            delay = Keyword.get(opts, :delay, 0)

            if delay == 0 do
              state.backend.send(message)
            else
              state.backend.send_after(message, delay)
            end
          end
        end
      )

    {:reply, result, state}
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

  def handle_call(:start_pollers, _from, state) do
    do_start_pollers(state.backend)

    {:reply, :ok, state}
  end

  def handle_call(:stop_pollers, _from, state) do
    PollerSup.stop_pollers()

    {:reply, :ok, state}
  end

  def handle_call(:clear_all_handlers, _from, state) do
    {:reply, :ok, %State{state | handlers: []}}
  end

  defp do_start_pollers(backend) do
    :ok = PollerSup.start_pollers(backend, __MODULE__)
  end

  defp auto_register_handlers do
    Enum.each(
      :code.all_loaded(),
      fn {mod, _} ->
        mod
        |> handler?()
        |> maybe_register_handler(mod)
      end
    )
  end

  defp handler?(mod) do
    mod.module_info(:attributes)
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(Dawdle.Handler)
  rescue
    _ -> false
  end

  defp maybe_register_handler(true, mod), do: mod.register()
  defp maybe_register_handler(false, _), do: :ok

  defp decode_and_forward_events(messages, state) do
    Enum.each(messages, &decode_and_forward_event(&1, state))
  end

  defp decode_and_forward_event(message, state) do
    Task.start(fn -> do_decode_and_forward_event(message, state) end)
  end

  defp do_decode_and_forward_event(message, state) do
    body =
      if Confex.get_env(:dawdle, :forward_raw_messages) do
        message
      else
        message.body
      end

    _ =
      case MessageEncoder.decode(body) do
        {:ok, decoded} ->
          forward_event(decoded, state.handlers)

        {:error, :unrecognized} ->
          Logger.warn("Dropping message in unknown format: #{message.body}")
      end

    state.backend.delete(message)
  end

  defp forward_event(%object{} = event, handlers) do
    results = Enum.map(handlers, &maybe_call_handler(&1, object, event))

    _ =
      unless Enum.any?(results, & &1) do
        Logger.warn("Unhandled event: #{inspect(event, pretty: true)}")
      end

    :ok
  end

  defp maybe_call_handler({handler, options}, object, event) do
    if should_call_handler?(options, object) do
      timed_fun(
        [:dawdle, :handler],
        %{handler: handler, options: options, object: object},
        fn -> do_call_handler(handler, event) end
      )

      true
    else
      false
    end
  end

  defp should_call_handler?([], _), do: true

  defp should_call_handler?(options, object) do
    except = Keyword.get(options, :except, [])
    only = Keyword.get(options, :only, [])

    !Enum.member?(except, object) && (only == [] || Enum.member?(only, object))
  end

  defp do_call_handler(handler, event) do
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
