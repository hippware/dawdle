defmodule Dawdle.MessageEncoder.Term do
  @moduledoc """
  Implements the `Dawdle.MessageEncoder` behaviour using
  `:erlang.term_to_binary/1` and `:erlang.binary_to_term/1`.

  The results are encoded with Base64 to ensure that they are safe to enqueue.
  """

  @behaviour Dawdle.MessageEncoder

  @impl true
  def encode(data) do
    string =
      data
      |> :erlang.term_to_binary(compressed: 6, minor_version: 2)
      |> Base.encode64(padding: false)

    {:ok, string}
  end

  @impl true
  def decode(string) do
    term =
      string
      |> Base.decode64!(ignore: :whitespace, padding: false)
      |> :erlang.binary_to_term()

    {:ok, term}
  rescue
    ArgumentError ->
      {:error, :unrecognized}
  end
end
