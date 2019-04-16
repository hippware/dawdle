defmodule Dawdle.MessageEncoder.Term do
  @moduledoc """
  Implements the `Dawdle.MessageEncoder` behaviour using
  `:erlang.term_to_binary/1` and `:erlang.binary_to_term/1`.

  The results are encoded with Base64 to ensure that they are safe to enqueue.
  """

  @behaviour Dawdle.MessageEncoder

  @impl true
  def encode(data) do
    data
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  @impl true
  def decode(string) do
    string
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end
end
