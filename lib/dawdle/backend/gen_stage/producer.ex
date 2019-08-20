defmodule Dawdle.Backend.GenStage.Producer do
  use GenStage

  @impl true
  def init(_) do
    {:producer, nil}
  end

  @impl true
  def handle_cast({:send, messages}, state) do
    {:noreply, transform_messages(messages), state}
  end

  @impl true
  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  def name, do: {:global, __MODULE__}

  defp transform_messages(messages) do
    Enum.map(messages, fn m -> %{body: m} end)
  end
end
