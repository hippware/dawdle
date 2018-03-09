defmodule Procrastinator.Backend.SQS.Supervisor do
  use Supervisor

  alias Procrastinator.Backend.SQS.Poller

  def start_link(queue_list, workers_per_queue, callback) do
    Supervisor.start_link(__MODULE__,
                          {queue_list, workers_per_queue, callback},
                          name: __MODULE__)
  end

  def init ({queue_list, workers_per_queue, callback}) do
    queue_list
    |> Enum.map(fn q -> {Poller, [q, callback]} end)
    |> Enum.map(&List.duplicate(&1, workers_per_queue))
    |> List.flatten()
    |> Supervisor.init(strategy: :one_for_one)
  end
end
