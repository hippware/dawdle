defmodule Dawdle.Backend.SQS do
  @moduledoc false

  alias ExAws.SQS

  @behaviour Dawdle.Backend

  def init, do: :ok

  def queues, do: [message_queue(), delay_queue()]

  def send([message]) do
    message_queue()
    |> SQS.send_message(message)
    |> ExAws.request(aws_config())
  end

  def send(messages) do
    message_queue()
    |> SQS.send_message_batch(batchify(messages))
    |> ExAws.request(aws_config())
  end

  def send_after(message, delay) do
    delay_queue()
    |> SQS.send_message(message, delay_seconds: delay)
    |> ExAws.request(aws_config())
  end

  def recv(queue) do
    result =
      queue
      |> SQS.receive_message()
      |> ExAws.request(aws_config())

    case result do
      {:ok, %{body: %{messages: []}}} -> recv(queue)
      {:ok, %{body: %{messages: messages}}} -> {:ok, messages}
    end
  end

  def delete(queue, messages) do
    {del_list, _} =
      Enum.map_reduce(messages, 0, fn m, id ->
        {%{id: Integer.to_string(id), receipt_handle: m.receipt_handle}, id + 1}
      end)

    queue
    |> SQS.delete_message_batch(del_list)
    |> ExAws.request(aws_config())

    :ok
  end

  defp message_queue, do: config(:message_queue)

  defp delay_queue, do: config(:delay_queue)

  defp aws_config, do: [region: config(:region)]

  defp config(term) do
    :dawdle
    |> Confex.fetch_env!(__MODULE__)
    |> Keyword.get(term)
  end

  defp id do
    [:monotonic]
    |> :erlang.unique_integer()
    |> Integer.to_string()
  end

  defp batchify(messages) do
    Enum.map(messages, fn m ->
      id = id()
      [id: id, message_body: m]
    end)
  end
end
