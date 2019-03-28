defmodule Dawdle.Poller.Supervisor do
  @moduledoc false

  use Supervisor

  alias Dawdle.Poller

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end

  @spec start_pollers(module(), module()) :: :ok
  def start_pollers(backend, send_to) do
    Enum.each(backend.queues(), &start_poller(backend, &1, send_to))
  end

  defp start_poller(source, queue, send_to) do
    case Supervisor.start_child(__MODULE__, {Poller, {source, queue, send_to}}) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  @spec stop_pollers() :: :ok
  def stop_pollers do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.each(fn {id, _, _, _} -> stop_poller(id) end)
  end

  defp stop_poller(poller) do
    :ok = Supervisor.terminate_child(__MODULE__, poller)
    :ok = Supervisor.delete_child(__MODULE__, poller)
  end
end
