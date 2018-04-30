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

    DawdleSQS.handle_messages(messages, queue)

    poll(queue)
  end

  def name(queue) do
    String.to_atom(Atom.to_string(__MODULE__) <> queue)
  end
end
