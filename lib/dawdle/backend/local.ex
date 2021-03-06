defmodule Dawdle.Backend.Local do
  @moduledoc """
  Implementation of the `Dawdle.Backend` behaviour that queues all events
  locally on a single node.

  This is intended for use in testing and development where a "live" backend
  like SQS is not available or desirable.
  """

  use GenServer

  @behaviour Dawdle.Backend

  @impl true
  def init do
    case GenServer.start_link(__MODULE__, [], name: __MODULE__) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    GenServer.call(__MODULE__, :flush)
  end

  @impl true
  def queue, do: "local"

  @impl true
  def send(message), do: GenServer.cast(__MODULE__, {:send, message})

  @impl true
  def send_after(message, delay) do
    # The SQS backend interprets the delay as seconds, whereas here we are
    # interpreting it as milliseconds. This is to allow us to test the delay
    # feature without the tests taking forever.
    {:ok, _} = :timer.apply_after(delay, __MODULE__, :send, [message])
    :ok
  end

  @impl true
  def recv, do: GenServer.call(__MODULE__, :recv, :infinity)

  @impl true
  def delete(_), do: :ok

  @doc false
  @spec count :: :non_neg_integer
  def count, do: GenServer.call(__MODULE__, :count)

  @doc false
  @spec flush :: :ok
  def flush, do: GenServer.call(__MODULE__, :flush)

  @impl true
  def init(_) do
    {:ok, {[], []}}
  end

  @impl true
  def handle_cast({:send, message}, {[], [waiter | rest]}) do
    GenServer.reply(waiter, {:ok, [transform_message(message)]})
    {:noreply, {[], rest}}
  end

  def handle_cast({:send, message}, {queue, []}) do
    {:noreply, {[transform_message(message) | queue], []}}
  end

  @impl true
  def handle_call(:recv, from, {[], waiters}) do
    {:noreply, {[], [from | waiters]}}
  end

  def handle_call(:recv, _from, {messages, []}) do
    {:reply, {:ok, Enum.reverse(messages)}, {[], []}}
  end

  def handle_call(:flush, _from, _) do
    {:reply, :ok, {[], []}}
  end

  def handle_call(:count, _from, {messages, _} = state) do
    {:reply, length(messages), state}
  end

  defp transform_message(message), do: %{body: message}
end
