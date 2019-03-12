defmodule Dawdle.Backend.Local do
  @moduledoc """
  Implementation of the `Dawdle.Backend` behaviour that queues all events
  locally on a single node.

  This is intended for use in testing and development where a "live" backend
  like SQS is not available or desirable.
  """

  use GenServer

  @behaviour Dawdle.Backend

  @impl Dawdle.Backend
  def init do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
    :ok
  end

  @impl Dawdle.Backend
  def queues, do: ["local"]

  @impl Dawdle.Backend
  def send(messages), do: GenServer.cast(__MODULE__, {:send, messages})

  @impl Dawdle.Backend
  def send_after(message, delay) do
    # The SQS backend interprets the delay as seconds, whereas here we are
    # interpreting it as milliseconds. This is to allow us to test the delay
    # feature without the tests taking forever.
    {:ok, _} = :timer.apply_after(delay, __MODULE__, :send, [[message]])
    :ok
  end

  @impl Dawdle.Backend
  def recv(_), do: GenServer.call(__MODULE__, :recv, :infinity)

  @impl Dawdle.Backend
  def delete(_, _), do: :ok

  @impl Dawdle.Backend
  def flush, do: GenServer.call(__MODULE__, :flush)

  @impl GenServer
  def init(_) do
    {:ok, {[], []}}
  end

  @impl GenServer
  def handle_cast({:send, messages}, {[], [waiter | rest]}) do
    GenServer.reply(waiter, {:ok, transform_messages(messages)})
    {:noreply, {[], rest}}
  end

  def handle_cast({:send, messages}, {queue, []}) do
    {:noreply, {queue ++ transform_messages(messages), []}}
  end

  @impl GenServer
  def handle_call(:recv, from, {[], waiters}) do
    {:noreply, {[], [from | waiters]}}
  end

  def handle_call(:recv, _from, {messages, []}) do
    {:reply, {:ok, messages}, {[], []}}
  end

  def handle_call(:flush, _from, _) do
    {:reply, :ok, {[], []}}
  end

  defp transform_messages(messages) do
    Enum.map(messages, fn m -> %{body: m} end)
  end
end
