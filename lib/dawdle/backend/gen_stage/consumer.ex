defmodule Dawdle.Backend.GenStage.Consumer do
  use GenStage

  alias Dawdle.Backend.GenStage.Producer

  @behaviour Dawdle.Poller

  @impl true
  @spec child_spec({module(), binary(), module()}) :: map()
  def child_spec({_source, queue, send_to}) do
    %{
      id: name(queue),
      start: {__MODULE__, :start_link, [queue, send_to]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(queue, send_to) do
    {:ok, consumer} =
      GenStage.start_link(__MODULE__, {queue, send_to}, name: name(queue))

    GenStage.sync_subscribe(consumer, to: Producer.name())
    {:ok, consumer}
  end

  @impl true
  def init({queue, send_to}) do
    {:consumer, {queue, send_to}}
  end

  @impl true
  def handle_events(events, _from, {queue, send_to} = state) do
    Enum.each(events, &send_to.recv(&1, queue))

    {:noreply, [], state}
  end

  defp name(queue) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    Module.concat(__MODULE__, queue)
  end
end
