defmodule Dawdle.Backend.SQS.Poller do
  @moduledoc false

  alias ExAws.SQS
  alias Dawdle.Backend.SQS, as: DawdleSQS

  def child_spec(queue) do
    %{
      id: name(queue),
      start: {__MODULE__, :start_link, [queue]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(queue) do
    Task.start_link(fn -> poll(queue) end)
  end

  def poll(queue) do
    {:ok, %{body: %{messages: messages}}} =
      queue
      |> SQS.receive_message(max_number_of_messages: 10)
      |> ExAws.request(DawdleSQS.aws_config())

    handle_messages(messages, queue)

    poll(queue)
  end

  defp handle_messages([], _), do: :ok

  defp handle_messages(messages, queue) do
    # Delete before firing the callback otherwise if the callback crashes
    # or quits (as it does in testing) the message won't be removed from the
    # SQS queue.
    delete(messages, queue)
    Enum.each(messages, &fire_callback(&1))
  end

  def fire_callback(%{body: body}) do
    {callback, message} = body |> Base.decode64!() |> :erlang.binary_to_term()
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
