defmodule Procrastinator do
  @moduledoc """
  Documentation for Procrastinator.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Procrastinator.hello
      :world

  """
  def start_link(callback) do
    backend().start_link(callback)
  end

  @spec send(term(), non_neg_integer()) :: :ok | {:error, term()}
  def send(message, delay) do
    backend().send(message, delay)
  end

  defp backend do
    Confex.get_env(Procrastinator, :backend, Procrastinator.Backend.Local)
  end
end
