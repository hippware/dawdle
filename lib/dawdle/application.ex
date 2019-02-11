defmodule Dawdle.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Dawdle.Client, []}
    ]

    opts = [strategy: :one_for_one, name: Dawdle.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
