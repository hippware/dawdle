defmodule Dawdle.Backend.SQS.Supervisor do
  @moduledoc false

  use Supervisor

  alias Dawdle.Backend.SQS.Poller

  def start_link(queue_list) do
    {:ok, _pid} =
      Supervisor.start_link(__MODULE__, queue_list, name: __MODULE__)
  end

  def init(queue_list) do
    queue_list
    |> Enum.map(fn q -> {Poller, q} end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
