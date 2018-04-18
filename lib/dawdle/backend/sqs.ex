defmodule Dawdle.Backend.SQS do
  alias ExAws.SQS
  alias Dawdle.Backend.SQS.Supervisor, as: SQSSupervisor

  @behaviour Dawdle.Backend

  def start_link(callback) do
    SQSSupervisor.start_link(config(:queues),
                             config(:workers_per_queue, 1),
                             callback)
  end

  def send(message, delay) do
    body = message |> :erlang.term_to_binary() |> Base.encode64()
    {:ok, _} =
      get_queue()
      |> SQS.send_message(
        body,
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
    :procrastinator
    |> Confex.fetch_env!(__MODULE__)
    |> Keyword.get(term, default)
  end
end
