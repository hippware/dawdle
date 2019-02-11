defmodule Dawdle.Backend do
  @moduledoc """
  Behaviour module for Dawdle backend implementation
  """

  @type send_message :: binary()
  @type recv_message :: map()

  @callback init() :: :ok
  @callback send([send_message()]) :: :ok | {:error, term()}
  @callback recv() :: {:ok, [recv_message()]} | {:error, term()}
  @callback delete([recv_message()]) :: :ok

  @type new() :: Module
  def new do
    backend = Confex.get_env(:dawdle, :backend)

    backend.init()

    backend
  end
end
