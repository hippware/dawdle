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
end
