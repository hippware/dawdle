defmodule Dawdle.MessageEncoder.Term do
  @moduledoc "Encodes messages using `term_to_binary`"

  @behaviour Dawdle.MessageEncoder

  def encode(data) do
    data
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  def decode(string) do
    string
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end
end
