defmodule Dawdle.Poller do
  @moduledoc false

  # A simple module that turns a blocking "pull" event source into a "push" one
  # that sends to another process.

  require Logger

  @base_backoff 100
  @max_backoff 120_000

  @spec child_spec({module(), module()}) :: map()
  def child_spec({source, send_to}) do
    %{
      id: name(source),
      start: {__MODULE__, :start_link, [source, send_to]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @spec start_link(module(), module()) :: {:ok, pid()}
  def start_link(source, send_to) do
    Task.start_link(fn -> poll(source, send_to) end)
  end

  defp poll(source, send_to, backoff \\ @base_backoff) do
    backoff =
      case source.recv() do
        {:ok, messages} ->
          send_to.recv(messages)

          @base_backoff

        {:error, _} ->
          Process.sleep(backoff)

          :backoff.rand_increment(backoff, @max_backoff)
      end

    poll(source, send_to, backoff)
  end

  defp name(source) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    Module.concat(__MODULE__, source)
  end
end
