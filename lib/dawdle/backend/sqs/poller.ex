defmodule Dawdle.Backend.SQS.Poller do
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
      |> SQS.receive_message()
      |> ExAws.request(DawdleSQS.aws_config())

    handle_messages(messages, queue, callback)

    poll(queue, callback)
  end

  defp handle_messages([], _, _), do: :ok
  defp handle_messages(messages, queue, callback) do
    Enum.each(messages, &fire_callback(&1, callback))
    delete(messages, queue)
  end

  def fire_callback(%{body: body}, callback) do
    message = body |> Base.decode64!() |> :erlang.binary_to_term()
    callback.(message)
  end

  def delete(messages, queue) do
    IO.inspect messages
    IO.inspect queue
    {del_list, _} =
      Enum.map_reduce(messages, 0, fn m, id ->
        {%{id: Integer.to_string(id), receipt_handle: m.receipt_handle}, id + 1}
      end)
    IO.inspect del_list

    queue
    |> SQS.delete_message_batch(del_list)
    |> ExAws.request(DawdleSQS.aws_config())
    |> IO.inspect
  end

  def name(queue) do
    String.to_atom(Atom.to_string(__MODULE__) <> queue)
  end
end
