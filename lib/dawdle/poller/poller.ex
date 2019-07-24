defmodule Dawdle.Poller do
  @moduledoc false

  # A simple module that turns a blocking "pull" event source into a "push" one
  # that sends to another process.

  require Logger

  @base_backoff 100
  @max_backoff 120_000

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

  defp poll(source, queue, send_to, backoff \\ @base_backoff) do
    backoff =
      case source.recv(queue) do
        {:ok, messages} ->
          messages
          |> Enum.map(fn m -> m.body end)
          |> send_to.recv(queue)

          @base_backoff

        {:error, _} ->
          Process.sleep(backoff)

          :backoff.rand_increment(backoff, @max_backoff)
      end

    poll(source, queue, send_to, backoff)
  end

  defp name(queue) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    Module.concat(__MODULE__, queue)
  end
end
