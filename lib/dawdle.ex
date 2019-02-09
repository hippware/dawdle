defmodule Dawdle do
  @moduledoc """
  Main module for the Dawdle messaging system.
  """

  @type argument :: any()
  @type callback :: (argument() -> any())
  @type duration :: non_neg_integer()

  @doc """
  Set a callback to be called the after `delay` ms
  """
  @spec call_after(callback(), argument(), duration()) :: :ok | {:error, term()}
  def call_after(_callback, _argument, _delay) do
    # backend().send(callback, argument, delay)
  end

  defdelegate signal(event), to: Dawdle.Client
end
