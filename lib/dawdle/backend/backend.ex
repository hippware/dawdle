defmodule Dawdle.Backend do
  @moduledoc """
  Behaviour module for Dawdle backend implementation
  """

  @type queue :: binary()
  @type send_message :: binary()
  @type recv_message :: map()
  @type delay_secs :: non_neg_integer()

  @callback init() :: :ok
  @callback queues() :: [queue()]
  @callback send([send_message()]) :: :ok | {:error, term()}
  @callback send_after(send_message(), delay_secs()) :: :ok | {:error, term()}
  @callback recv(queue()) :: {:ok, [recv_message()]} | {:error, term()}
  @callback delete(queue(), [recv_message()]) :: :ok
  @callback flush() :: :ok

  @type new() :: Module
  def new do
    backend = Confex.get_env(:dawdle, :backend)

    backend.init()

    backend
  end
end
