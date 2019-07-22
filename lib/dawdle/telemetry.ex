defmodule Dawdle.Telemetry do
  @moduledoc false

  # Helpers for executing Telemetry events in Dawdle.

  @spec timed_fun([atom(), ...], map(), map(), (() -> result)) :: result
        when result: any()
  def timed_fun(name, metadata, measurements \\ %{}, fun) do
    {duration, result} = :timer.tc(fun)

    :telemetry.execute(
      name,
      Map.put(measurements, :duration, duration),
      metadata
    )

    result
  end
end
