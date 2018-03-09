defmodule Procrastinator.Backend.SQS do
  alias ExAws.SQS
  alias Procrastinator.Backend.SQS.Supervisor, as: SQSSupervisor

  @behaviour Procrastinator.Backend

  def start_link(callback) do
    SQSSupervisor.start_link(config(:queues),
                             config(:workers_per_queue, 1),
                             callback)
  end

  @group_id "procrastinator"

  def init, do: :ok

  def send(message, delay) do
    get_queue()
    |> SQS.send_message(
      message,
      message_group_id: @group_id,
      delay_seconds: div(delay, 1000)
    )
    |> ExAws.request(aws_config())
  end

  defp get_queue() do
    :queues
    |> config()
    |> Enum.random()
  end

  def aws_config, do: [region: config(:region)]

  def config(term, default \\ nil) do
    Procrastinator
    |> Confex.fetch_env!(__MODULE__)
    |> Keyword.get(term, default)
  end
end
