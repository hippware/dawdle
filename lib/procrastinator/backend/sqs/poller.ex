defmodule Procrastinator.Backend.SQS.Poller do
  alias ExAws.SQS
  alias Procrastinator.Backend.SQS, as: ProcSQS

  def start_link(queue, callback) do
    Task.start_link(fn -> poll(queue, callback) end)
  end

  def poll(queue, callback) do
    {:ok, %{body: %{messages: messages}}} =
      queue
      |> SQS.receive_message()
      |> ExAws.request(ProcSQS.aws_config())

    handle_messages(messages, queue, callback)

    poll(queue, callback)
  end

  defp handle_messages([], _, _), do: :ok
  defp handle_messages(messages, queue, callback) do
    Enum.each(messages, &callback.(&1))
    delete(messages, queue)
  end

  def delete(messages, queue) do
    {del_list, _} =
      Enum.map_reduce(messages, 0, fn m, id ->
        {%{id: Integer.to_string(id), receipt_handle: m.receipt_handle}, id + 1}
      end)

    queue
    |> SQS.delete_message_batch(del_list)
    |> ExAws.request(ProcSQS.aws_config())
  end
end
