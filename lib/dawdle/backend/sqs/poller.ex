defmodule Dawdle.Backend.SQS.Poller do
  @moduledoc false

  alias ExAws.SQS
  alias Dawdle.Backend.SQS, as: DawdleSQS

  def child_spec([queue, callback]) do
    %{
      id: name(queue),
      start: {__MODULE__, :start_link, [queue, callback]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(queue, callback) do
    Task.start_link(fn -> poll(queue, callback) end)
  end

  def poll(queue, callback) do
    {:ok, %{body: %{messages: messages}}} =
      queue
      |> SQS.receive_message(max_number_of_messages: 10)
      |> ExAws.request(DawdleSQS.aws_config())

    handle_messages(messages, queue, callback)

    poll(queue, callback)
  end

  defp handle_messages([], _, _), do: :ok

  defp handle_messages(messages, queue, callback) do
    # Delete before firing the callback otherwise if the callback crashes
    # or quits (as it does in testing) the message won't be removed from the
    # SQS queue.
    delete(messages, queue)
    Enum.each(messages, &fire_callback(&1, callback))
  end

  def fire_callback(%{body: body}, callback) do
    message = body |> Base.decode64!() |> :erlang.binary_to_term()
    callback.(message)
  end

  def delete(messages, queue) do
    {del_list, _} =
      Enum.map_reduce(messages, 0, fn m, id ->
        {%{id: Integer.to_string(id), receipt_handle: m.receipt_handle}, id + 1}
      end)

    queue
    |> SQS.delete_message_batch(del_list)
    |> ExAws.request(DawdleSQS.aws_config())
  end

  def name(queue) do
    String.to_atom(Atom.to_string(__MODULE__) <> queue)
  end
end
