defmodule Dawdle.MessageEncoder do
  @moduledoc """
  Behaviour for Dawdle event encoding.

  Dawdle wants to enqueue Elixir structs and other Erlang terms. This behaviour
  specifies an interface for translating an event, i.e., term, into a string
  that can be safely enqueued.
  """

  import Dawdle.Telemetry

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
  def encode(event) do
    encoder = get_encoder()

    timed_fun(:encode, %{encoder: encoder}, fn -> encoder.encode(event) end)
  end

  @spec decode(String.t()) :: any()
  def decode(message) do
    encoder = get_encoder()

    timed_fun(:decode, %{encoder: encoder}, fn -> encoder.decode(message) end)
  end

  defp get_encoder do
    Application.get_env(:dawdle, :encoder, @default_encoder)
  end
end
