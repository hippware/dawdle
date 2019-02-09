defmodule Dawdle.MessageEncoder do
  @moduledoc "Behavior for message encoding"

  @callback encode(any()) :: String.t()
  @callback decode(String.t()) :: any()
end
