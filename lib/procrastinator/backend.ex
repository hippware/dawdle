defmodule Procrastinator.Backend do
  @moduledoc """
  Behaviour module for Procrastinator backend implementation
  """

  @type message :: binary()
  @type callback :: (message() -> any())

  @callback start_link(callback()) :: {:ok, pid()}
  @callback send(message(), non_neg_integer()) :: :ok | {:error, term()}
end
