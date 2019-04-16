defmodule Dawdle.TestHelper do
  @moduledoc """
  Helper functions for writing tests that interact with Dawdle handlers.
  """

  @doc "Clear all currently registered Dawdle handlers."
  @spec clear_all_handlers :: :ok
  defdelegate clear_all_handlers, to: Dawdle.Client
end
