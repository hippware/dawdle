defmodule Dawdle.Backend.SQS.Supervisor do
  @moduledoc false

  use Supervisor

  alias Dawdle.Backend.SQS.Poller

  def start_link(queue_list, callback) do
    {:ok, _pid} =
      Supervisor.start_link(
        __MODULE__,
        {queue_list, callback},
        name: __MODULE__
      )
  end

  def init({queue_list, callback}) do
    queue_list
    |> Enum.map(fn q -> {Poller, [q, callback]} end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
