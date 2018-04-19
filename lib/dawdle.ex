defmodule Dawdle do
  @moduledoc ~S"""
  Documentation for Dawdle.
  """

  @doc """
  """

  @type message :: any()
  @type callback :: (message() -> any())
  @type duration :: non_neg_integer()

  def start_link, do: backend().start_link()

  @doc """
  Send a message to be fired back after at least the specified delay in ms
  """
  @spec send(callback(), message(), duration()) :: :ok | {:error, term()}
  def send(callback, message, delay) do
    backend().send(callback, message, delay)
  end

  defp backend do
    Confex.get_env(:dawdle, :backend, Dawdle.Backend.Local)
  end
end
