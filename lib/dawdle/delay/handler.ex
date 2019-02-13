defmodule Dawdle.Delay.Handler do
  @moduledoc false

  use Dawdle.Handler, types: [Dawdle.Delay.DelayedFunction]

  alias Dawdle.Client
  alias Dawdle.Delay.DelayedFunction

  @max_delay 15 * 60

  def call(fun) do
    Client.signal(%DelayedFunction{fun: fun})
  end

  def call_after(delay, fun) do
    do_send(%DelayedFunction{fun: fun}, delay)
  end

  def handle_event(%DelayedFunction{delay: delay} = event)
      when not is_nil(delay) and delay > 0 do
    do_send(event, delay)
  end

  def handle_event(%DelayedFunction{fun: fun}) do
    fun.()
  end

  defp do_send(%DelayedFunction{} = event, delay) do
    this_delay = min(delay, @max_delay)
    event = %DelayedFunction{event | delay: delay - this_delay}

    Client.signal(event, this_delay)
  end
end
