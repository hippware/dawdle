defmodule Dawdle.Backend.Local do
  use GenServer

  @behaviour Dawdle.Backend

  def start_link(callback) do
    GenServer.start_link(__MODULE__, callback, name: __MODULE__)
  end

  def send(message, delay) do
    GenServer.cast(__MODULE__, {:send, message, delay})
  end

  def init(callback) do
    {:ok, callback}
  end

  def handle_cast({:send, message, delay}, callback) do
    :timer.apply_after(delay, __MODULE__, :recv, [callback, message])
    {:noreply, callback}
  end

  def recv(callback, message) do
    callback.(message)
  end
end
