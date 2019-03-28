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
      |> ExAws.request(aws_config())

    _ =
      Logger.info(fn ->
        """
        Sent message to #{message_queue()}:
          message: #{inspect(message, pretty: true)}"
          result: #{inspect(result, pretty: true)}
        """
      end)

    normalize(result)
  end

  def send(messages) do
    result =
      message_queue()
      |> SQS.send_message_batch(batchify(messages))
      |> ExAws.request(aws_config())

    _ =
      Logger.info(fn ->
        """
        Sent #{length(messages)} messages to #{message_queue()}:
          messages: #{inspect(messages, pretty: true)}
          result: #{inspect(result, pretty: true)}
        """
      end)

    normalize(result)
  end

  @impl true
  def send_after(message, delay) do
    result =
      delay_queue()
      |> SQS.send_message(message, delay_seconds: delay)
      |> ExAws.request(aws_config())

    _ =
      Logger.info(fn ->
        """
        Sent message to #{delay_queue()} with delay of #{delay}:
          message: #{inspect(message, pretty: true)}
          result: #{inspect(result, pretty: true)}
        """
      end)

    normalize(result)
  end

  @impl true
  def recv(queue) do
    result =
      queue
      |> SQS.receive_message(max_number_of_messages: 10)
      |> ExAws.request(aws_config())

    case result do
      {:ok, %{body: %{messages: []}}} ->
        _ = Logger.debug(fn -> "Empty receive from '#{queue}'" end)

        recv(queue)

      {:ok, %{body: %{messages: messages}}} ->
        _ =
          Logger.info(fn ->
            "Received messages from '#{queue}': " <>
              "#{inspect(messages, pretty: true)}"
          end)

        {:ok, messages}
    end
  end

  @impl true
  def delete(queue, messages) do
    {del_list, _} =
      Enum.map_reduce(messages, 0, fn m, id ->
        {%{id: Integer.to_string(id), receipt_handle: m.receipt_handle}, id + 1}
      end)

    result =
      queue
      |> SQS.delete_message_batch(del_list)
      |> ExAws.request(aws_config())

    _ =
      Logger.info(fn ->
        """
        Deleted messages from '#{queue}':
          messages: #{inspect(messages, pretty: true)}"
          result: #{inspect(result, pretty: true)}
        """
      end)

    normalize(result)
  end

  defp message_queue, do: config(:message_queue)

  defp delay_queue, do: config(:delay_queue)

  defp aws_config, do: [region: config(:region)]

  defp config(term) do
    Confex.fetch_env!(:dawdle, __MODULE__)
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

  defp normalize({:ok, _}), do: :ok
  defp normalize(result), do: result
end
