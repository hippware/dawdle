defmodule Dawdle do
  @moduledoc """
  Main module for the Dawdle messaging system.
  """

  @type duration :: non_neg_integer()
  @type fun :: (() -> any())
  @type event :: struct()

  @spec call(fun()) :: :ok | {:error, term()}
  defdelegate call(fun), to: Dawdle.Delay.Handler

  @doc """
  Set a callback to be called the after `delay` ms
  """
  @spec call_after(duration(), fun()) :: :ok | {:error, term()}
  defdelegate call_after(delay, fun), to: Dawdle.Delay.Handler

  @spec signal(event()) :: :ok
  defdelegate signal(event), to: Dawdle.Client
end
