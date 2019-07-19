defmodule Dawdle.MessageEncoder do
  @moduledoc """
  Behaviour for Dawdle event encoding.

  Dawdle wants to enqueue Elixir structs and other Erlang terms. This behaviour
  specifies an interface for translating an event, i.e., term, into a string
  that can be safely enqueued.
  """

  @doc """
  Encode an event into a string that is safe to enqueue.
  """
  @callback encode(event :: any()) :: String.t()

  @doc """
  Decode a string pulled from the queue into its original representation.
  """
  @callback decode(message :: String.t()) :: any()

  @default_encoder Dawdle.MessageEncoder.Term

  @spec encode(any()) :: String.t()
  def encode(event), do: timed_op(:encode, event)

  @spec decode(String.t()) :: any()
  def decode(message), do: timed_op(:decode, message)

  defp get_encoder do
    Application.get_env(:dawdle, :encoder, @default_encoder)
  end

  defp timed_op(op, data) do
    encoder = get_encoder()

    start_time = System.monotonic_time()
    :telemetry.execute(
      [:dawdle, op, :start],
      %{time: start_time},
      %{encoder: encoder}
    )

    result = apply(encoder, op, [data])

    duration = System.monotonic_time() - start_time
    :telemetry.execute(
      [:dawdle, op, :stop],
      %{duration: duration},
      %{encoder: encoder}
    )

    result
  end
end
