defmodule Dawdle.Backend do
  @moduledoc """
  Behaviour for Dawdle backends.

  Dawdle backends are responsible for interfacing with the actual message queue.
  """

  @type queue :: binary()
  @type send_message :: binary()
  @type recv_message :: map()
  @type delay_secs :: non_neg_integer()

  @callback init() :: :ok
  @callback queues() :: [queue()]
  @callback poller() :: module()
  @callback send([send_message()]) :: :ok | {:error, term()}
  @callback send_after(send_message(), delay_secs()) :: :ok | {:error, term()}
  @callback recv(queue()) :: {:ok, [recv_message()]} | {:error, term()}
  @callback delete(queue(), [recv_message()]) :: :ok

  @doc """
  Returns an initialized backend.

  Looks up the preferred backend in the application environment and calls the
  backend's `c:init/0` callback.
  """
  @spec new() :: module()
  def new do
    backend = Confex.get_env(:dawdle, :backend)

    backend.init()

    backend
  end
end
