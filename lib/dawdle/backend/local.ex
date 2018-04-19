defmodule Dawdle.Backend.Local do
  @moduledoc false

  use GenServer

  @behaviour Dawdle.Backend

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def send(callback, message, delay) do
    GenServer.cast(__MODULE__, {:send, callback, message, delay})
  end

  def init(nil) do
    {:ok, nil}
  end

  def handle_cast({:send, callback, message, delay}, state) do
    :timer.apply_after(delay, __MODULE__, :recv, [callback, message])
    {:noreply, state}
  end

  def recv(callback, message) do
    callback.(message)
  end
end
