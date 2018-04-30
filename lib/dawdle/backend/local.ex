defmodule Dawdle.Backend.Local do
  @moduledoc false

  use GenServer

  @behaviour Dawdle.Backend

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def send(callback, argument, delay) do
    GenServer.cast(__MODULE__, {:send, callback, argument, delay})
  end

  def init(nil) do
    {:ok, nil}
  end

  def handle_cast({:send, callback, argument, delay}, state) do
    :timer.apply_after(delay, __MODULE__, :recv, [callback, argument])
    {:noreply, state}
  end

  def recv(callback, argument) do
    callback.(argument)
  end
end
