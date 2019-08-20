defmodule Dawdle.Backend.GenStage do
  @moduledoc """
  Implementation of the `Dawdle.Backend` behaviour that uses a GenStage
  producer/consumer model.
  """

  alias Dawdle.Backend.GenStage.Producer
  alias Dawdle.Backend.GenStage.Consumer

  @behaviour Dawdle.Backend

  @impl true
  def init do
    case GenStage.start_link(Producer, [], name: Producer.name()) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  @impl true
  def queues, do: ["gen_stage"]

  @impl true
  def poller, do: Consumer

  @impl true
  def send(messages), do: GenStage.cast({:global, Producer}, {:send, messages})

  @impl true
  def send_after(message, delay) do
    {:ok, _} = :timer.apply_after(delay, __MODULE__, :send, [[message]])
    :ok
  end

  @impl true
  def recv(_), do: {:error, :not_implemented}

  @impl true
  def delete(_, _), do: :ok
end
