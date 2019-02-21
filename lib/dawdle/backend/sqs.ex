defmodule Dawdle.Backend.SQS do
  @moduledoc false

  alias ExAws.SQS

  require Logger

  @behaviour Dawdle.Backend
  @group_id "dawdle_db"

  def init, do: :ok

  def queues, do: [message_queue(), delay_queue()]

  def send([message]) do
    result =
      message_queue()
      |> SQS.send_message(message,
        message_group_id: @group_id,
        message_deduplication_id: id()
      )
      |> send_request()

    Logger.info(
      "Sent message to #{message_queue()} with result #{result}: #{message}"
    )

    result
  end

  def send(messages) do
    message_queue()
    |> SQS.send_message_batch(batchify(messages))
    |> send_request()
  end

  def send_after(message, delay) do
    delay_queue()
    |> SQS.send_message(message, delay_seconds: delay)
    |> send_request()
  end

  defp send_request(request) do
    with {:ok, _} <- ExAws.request(request, aws_config()) do
      :ok
    end
  end

  def recv(queue) do
    result =
      queue
      |> SQS.receive_message()
      |> ExAws.request(aws_config())

    Logger.debug(fn ->
      "Receive results from queue #{queue}: #{inspect(result)}"
    end)

    case result do
      {:ok, %{body: %{messages: []}}} ->
        recv(queue)

      {:ok, %{body: %{messages: messages}}} ->
        Logger.info("Received messages from '#{queue}': #{inspect(messages)}")
        {:ok, messages}
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

    Logger.info("Deleted messages from '#{queue}': #{inspect(messages)}")

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

      [
        id: id,
        message_body: m,
        message_deduplication_id: id,
        message_group_id: @group_id
      ]
    end)
  end
end
