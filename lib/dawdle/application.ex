defmodule Dawdle.Application do
  @moduledoc false

  use Application

  alias Dawdle.Delay.Handler, as: DelayHandler

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Dawdle.Poller.Supervisor,
      Dawdle.Client
    ]

    opts = [strategy: :one_for_one, name: Dawdle.Supervisor]
    sup = Supervisor.start_link(children, opts)

    DelayHandler.register()

    sup
  end
end
