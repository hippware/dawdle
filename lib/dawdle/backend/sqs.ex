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
  def send(message), do: do_send(message)

  @impl true
  def send_after(message, delay), do: do_send(message, delay_seconds: delay)

  defp do_send(message, opts \\ []) do
    queue = queue()

    result =
      queue
      |> SQS.send_message(message, opts)
      |> request()

    do_log_result(
      result,
      """
      Sent message to #{queue}:
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
  def delete(message) do
    queue = queue()

    result =
      queue
      |> SQS.delete_message(message.receipt_handle)
      |> request()

    do_log_result(
      result,
      """
      Deleted message from '#{queue}':
        message: #{inspect(message, pretty: true)}"
        result: #{inspect(result, pretty: true)}
      """
    )

    normalize(result)
  end

  defp request(data), do: ExAws.request(data, region: get_config(:region))

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
