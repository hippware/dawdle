defmodule Dawdle do
  @moduledoc ~S"""
  Main module for Dawdle dealy system.
  """

  @doc """
  """

  @type argument :: any()
  @type callback :: (argument() -> any())
  @type duration :: non_neg_integer()

  @spec start_link() :: {:ok, pid()}
  def start_link, do: backend().start_link()

  @doc """
  Set a callback to be called the eafter `delay` ms
  """
  @spec call_after(callback(), argument(), duration()) :: :ok | {:error, term()}
  def call_after(callback, argument, delay) do
    backend().send(callback, argument, delay)
  end

  defp backend do
    Confex.get_env(:dawdle, :backend, Dawdle.Backend.Local)
  end
end
