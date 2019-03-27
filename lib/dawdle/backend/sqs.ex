defmodule Dawdle.Backend.SQS do
  @moduledoc """
  Implementation of the `Dawdle.Backend` behaviour for Amazon SQS.
  """

  alias ExAws.SQS

  require Logger

  @behaviour Dawdle.Backend
  @group_id "dawdle_db"

  @impl true
  def init, do: :ok

  @impl true
  def queues, do: [message_queue(), delay_queue()]

  @impl true
  def send([message]) do
    result =
      message_queue()
      |> SQS.send_message(message,
        message_group_id: @group_id,
        message_deduplication_id: id()
      )
      |> send_request()

    :ok =
      Logger.info(
        "Sent message to #{message_queue()} with result '#{inspect(result)}': " <>
          "#{inspect(message, pretty: true)}"
      )

    result
  end

  def send(messages) do
    result =
      message_queue()
      |> SQS.send_message_batch(batchify(messages))
      |> send_request()

    :ok =
      Logger.info(
        "Sent #{length(messages)} messages to #{message_queue()} with result " <>
          "'#{inspect(result)}': #{inspect(messages, pretty: true)}"
      )

    result
  end

  @impl true
  def send_after(message, delay) do
    result =
      delay_queue()
      |> SQS.send_message(message, delay_seconds: delay)
      |> send_request()

    :ok =
      Logger.info(
        "Sent delayed message to #{delay_queue()} with result " <>
          "'#{inspect(result)}': #{inspect(message, pretty: true)}"
      )

    result
  end

  defp send_request(request) do
    with {:ok, _} <- ExAws.request(request, aws_config()) do
      :ok
    end
  end

  @impl true
  def recv(queue) do
    result =
      queue
      |> SQS.receive_message(max_number_of_messages: 10)
      |> ExAws.request(aws_config())

    :ok =
      Logger.debug(fn ->
        "Receive results from queue #{queue}: #{inspect(result, pretty: true)}"
      end)

    case result do
      {:ok, %{body: %{messages: []}}} ->
        recv(queue)

      {:ok, %{body: %{messages: messages}}} ->
        :ok =
          Logger.info(
            "Received messages from '#{queue}': #{
              inspect(messages, pretty: true)
            }"
          )

        {:ok, messages}
    end
  end

  @impl true
  def delete(queue, messages) do
    {del_list, _} =
      Enum.map_reduce(messages, 0, fn m, id ->
        {%{id: Integer.to_string(id), receipt_handle: m.receipt_handle}, id + 1}
      end)

    :ok =
      Logger.info(
        "Deleted messages from '#{queue}': #{inspect(messages, pretty: true)}"
      )

    queue
    |> SQS.delete_message_batch(del_list)
    |> send_request()
  end

  @impl true
  def flush do
    Enum.each(queues(), &do_flush(&1))
  end

  defp do_flush(queue) do
    :ok = Logger.debug(fn -> "Purging queue '#{queue}'" end)

    queue
    |> SQS.purge_queue()
    |> ExAws.request(aws_config())
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
    :crypto.strong_rand_bytes(16)
    |> Base.hex_encode32(padding: false)
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
