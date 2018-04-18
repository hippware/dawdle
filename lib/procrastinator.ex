defmodule Procrastinator do
  @moduledoc ~S"""
  Documentation for Procrastinator.
  """

  @doc """
  """
  def start_link(callback), do: backend().start_link(callback)

  @doc """
  Send a message to be fired back after at least the specified delay in ms
  """
  @spec send(term(), non_neg_integer()) :: :ok | {:error, term()}
  def send(message, delay) do
    backend().send(message, delay)
  end

  defp backend do
    Confex.get_env(:procrastinator, :backend, Procrastinator.Backend.Local)
  end
end
