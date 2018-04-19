defmodule Dawdle do
  @moduledoc ~S"""
  Main module for Dawdle dealy system.
  """

  @doc """
  """

  @type message :: any()
  @type callback :: (message() -> any())
  @type duration :: non_neg_integer()

  @spec start_link() :: {:ok, pid()}
  def start_link, do: backend().start_link()

  @doc """
  Set a callback to be called the eafter `delay` ms
  """
  @spec call_after(callback(), message(), duration()) :: :ok | {:error, term()}
  def call_after(callback, message, delay) do
    backend().send(callback, message, delay)
  end

  defp backend do
    Confex.get_env(:dawdle, :backend, Dawdle.Backend.Local)
  end
end
