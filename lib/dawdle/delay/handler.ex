defmodule Dawdle.Delay.Handler do
  @moduledoc false

  use Dawdle.Handler, only: [Dawdle.Delay.DelayedFunction]

  alias Dawdle.Client
  alias Dawdle.Delay.DelayedFunction

  @max_delay 15 * 60

  @spec call(fun()) :: :ok | {:error, term()}
  def call(fun) do
    Client.signal(%DelayedFunction{fun: fun})
  end

  @spec call_after(Dawdle.duration(), fun()) :: :ok | {:error, term()}
  def call_after(delay, fun) do
    do_send(%DelayedFunction{fun: fun}, delay)
  end

  @impl true
  def handle_event(%DelayedFunction{delay: delay} = event)
      when not is_nil(delay) and delay > 0 do
    do_send(event, delay)
  end

  @impl true
  def handle_event(%DelayedFunction{fun: fun}) do
    fun.()
  end

  defp do_send(%DelayedFunction{} = event, delay) do
    this_delay = min(delay, @max_delay)
    event = %DelayedFunction{event | delay: delay - this_delay}

    Client.signal(event, delay: this_delay)
  end
end
