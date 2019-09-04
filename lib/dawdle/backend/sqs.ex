defmodule Dawdle.Backend.SQS do
  @moduledoc """
  Implementation of the `Dawdle.Backend` behaviour for Amazon SQS.
  """

  use ModuleConfig, otp_app: :dawdle

  alias ExAws.SQS

  require Logger

  @behaviour Dawdle.Backend

  @impl true
  def init, do: :ok

  @impl true
  def queue, do: get_config(:queue_url)

  @impl true
  def send([message]) do
    queue = queue()

    result =
      queue
      |> SQS.send_message(message)
      |> request()

    do_log_result(
      result,
      """
      Sent message to #{queue}:
        message: #{inspect(message, pretty: true)}"
        result: #{inspect(result, pretty: true)}
      """
    )

    normalize(result)
  end

  def send(messages) do
    queue = queue()

    result =
      queue
      |> SQS.send_message_batch(batchify(messages))
      |> request()

    do_log_result(
      result,
      """
      Sent #{length(messages)} messages to #{queue}:
        messages: #{inspect(messages, pretty: true)}
        result: #{inspect(result, pretty: true)}
      """
    )

    normalize(result)
  end

  @impl true
  def send_after(message, delay) do
    queue = queue()

    result =
      queue
      |> SQS.send_message(message, delay_seconds: delay)
      |> request()

    do_log_result(
      result,
      """
      Sent message to #{queue} with delay of #{delay}:
        message: #{inspect(message, pretty: true)}
        result: #{inspect(result, pretty: true)}
      """
    )

    normalize(result)
  end

  @impl true
  def recv do
    queue = queue()

    soak_ssl_messages()

    result =
      queue
      |> SQS.receive_message(max_number_of_messages: 10)
      |> request()

    case result do
      {:ok, %{body: %{messages: []}}} ->
        _ = Logger.debug(fn -> "Empty receive from '#{queue}'" end)

        recv()

      {:ok, %{body: %{messages: messages}}} ->
        _ =
          Logger.debug(fn ->
            "Received messages from '#{queue}': " <>
              "#{inspect(messages, pretty: true)}"
          end)

        {:ok, messages}

      {:error, _} = error ->
        _ =
          Logger.error("""
          Error receiving messages from queue #{queue}:
            #{inspect(error, pretty: true)}
          """)

        error
    end
  end

  @impl true
  def delete(messages) do
    queue = queue()

    {del_list, _} =
      Enum.map_reduce(messages, 0, fn m, id ->
        {%{id: Integer.to_string(id), receipt_handle: m.receipt_handle}, id + 1}
      end)

    result =
      queue
      |> SQS.delete_message_batch(del_list)
      |> request()

    do_log_result(
      result,
      """
      Deleted messages from '#{queue}':
        messages: #{inspect(messages, pretty: true)}"
        result: #{inspect(result, pretty: true)}
      """
    )

    normalize(result)
  end

  defp request(data), do: ExAws.request(data, region: get_config(:region))

  defp id do
    :crypto.strong_rand_bytes(16)
    |> Base.hex_encode32(padding: false)
  end

  defp batchify(messages) do
    Enum.map(messages, fn m ->
      [id: id(), message_body: m]
    end)
  end

  defp normalize({:ok, _}), do: :ok
  defp normalize(result), do: result

  defp do_log_result(result, message) do
    level =
      case result do
        {:ok, _} -> :debug
        {:error, _} -> :error
      end

    _ = Logger.log(level, message)

    :ok
  end

  # Workaround for issue https://github.com/benoitc/hackney/issues/464 to stop
  # :ssl_closed messages building up in our queue. It appears to only occur
  # on the recv end, not the send one - I suspect that's because it is triggered
  # when we do an SQS receive call that times out without response.
  defp soak_ssl_messages do
    receive do
      {:ssl_closed, _} -> soak_ssl_messages()
    after
      0 -> :ok
    end
  end
end
