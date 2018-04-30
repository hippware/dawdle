defmodule Dawdle.Backend.SQS do
  @moduledoc false

  alias ExAws.SQS
  alias Dawdle.Backend.SQS.Supervisor, as: SQSSupervisor

  @max_delay 15 * 60

  defstruct [
    :remaining_delay,
    :callback,
    :argument
  ]

  @type t :: %__MODULE__{
    remaining_delay: Dawdle.duration,
    callback: Dawdle.callback,
    argument: Dawdle.argument
  }

  @behaviour Dawdle.Backend

  def start_link() do
    SQSSupervisor.start_link(config(:queues))
  end

  ## Outgoing handlers
  def send(callback, argument, delay_ms) do

    %__MODULE__{
      remaining_delay: div(delay_ms, 1000),
      callback: callback,
      argument: argument
    }
    |> send_message()
  end

  defp send_message(%__MODULE__{remaining_delay: remaining_delay} = message) do
    this_delay = min(remaining_delay, config(:max_delay, @max_delay))

    body =
      %{message | remaining_delay: remaining_delay - this_delay}
      |> :erlang.term_to_binary()
      |> Base.encode64()

    {:ok, _} =
      get_queue()
      |> SQS.send_message(body, delay_seconds: this_delay)
      |> ExAws.request(aws_config())

    :ok
  end

  defp get_queue() do
    :queues
    |> config()
    |> Enum.random()
  end

  def aws_config, do: [region: config(:region)]

  def config(term, default \\ nil) do
    :dawdle
    |> Confex.fetch_env!(__MODULE__)
    |> Keyword.get(term, default)
  end

  ## Incoming handlers
  def handle_messages([], _), do: :ok

  def handle_messages(messages, queue) do
    # Delete before firing the callback otherwise if the callback crashes
    # or quits (as it does in testing) the message won't be removed from the
    # SQS queue.
    delete(messages, queue)
    Enum.each(messages, &decode_and_handle(&1))
  end

  defp decode_and_handle(%{body: body}) do
    try  do
      body
      |> Base.decode64!()
      |> :erlang.binary_to_term([:safe])
      |> handle_message()

      :ok
    catch
      _ -> :ok
    end
  end

  defp handle_message(%__MODULE__{remaining_delay: remaining_delay} = message)
  when remaining_delay > 0 do
    send_message(message)
  end

  defp handle_message(%__MODULE__{callback: callback, argument: argument}) do
    callback.(argument)
  end

  defp delete(messages, queue) do
    {del_list, _} =
      Enum.map_reduce(messages, 0, fn m, id ->
        {%{id: Integer.to_string(id), receipt_handle: m.receipt_handle}, id + 1}
      end)

    queue
    |> SQS.delete_message_batch(del_list)
    |> ExAws.request(aws_config())
  end

end
