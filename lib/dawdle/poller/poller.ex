defmodule Dawdle.Poller do
  @moduledoc false

  # A simple module that turns a blocking "pull" event source into a "push" one
  # that sends to another process.

  require Logger

  @spec child_spec({module(), binary(), module()}) :: map()
  def child_spec({source, queue, send_to}) do
    %{
      id: name(queue),
      start: {__MODULE__, :start_link, [source, queue, send_to]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @spec start_link(module(), binary(), module()) :: {:ok, pid()}
  def start_link(source, queue, send_to) do
    Task.start_link(fn -> poll(source, queue, send_to) end)
  end

  defp poll(source, queue, send_to) do
    {:ok, messages} = source.recv(queue)

    messages
    |> Enum.map(fn m -> m.body end)
    |> send_to.recv()

    source.delete(queue, messages)
  rescue
    exception ->
      Logger.error("Dawdle poller crash: #{inspect(exception)}")
  after
    poll(source, queue, send_to)
  end

  defp name(queue) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    Module.concat(__MODULE__, queue)
  end
end
