defmodule Dawdle.Poller.Supervisor do
  @moduledoc false

  use Supervisor

  alias Dawdle.Poller

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end

  def start_pollers(backend, send_to) do
    Enum.map(backend.queues(), &start_poller(backend, &1, send_to))
  end

  def start_poller(source, queue, send_to) do
    Supervisor.start_child(__MODULE__, {Poller, {source, queue, send_to}})
  end
end
