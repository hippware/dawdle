# Dawdle

Dawdle provides a service similar to Erlang's `timer:apply_after/4`, but in a
distributed and node-failure-tolerant manner using AWS's Simple Queue Service
(SQS).

This means that if, for example, you're running your BEAM system in a
Kubernetes cluster, and one or more of your pods die or are restarted or
terminated or what have you, your timeouts will still fire and be handled
by whatever pods are available. If no pods are available for some reason,
the timeouts will still be preserved and can be handled when a pod is
available again to service them.

## Installation

Add `dawdle` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dawdle, "~> 0.3.0"}
  ]
end
```

## Configuration

Dawdle provides two backends: A local one for development and testing which does
not require access to SQS (the default), and an SQS one for use in an AWS
environment.

To enable the SQS backend, set the following in your application's `config.exs`:

```elixir
config :dawdle,
    backend: Dawdle.Backend.SQS
```

To configure your SQS queues, set the following:

```elixir
config :dawdle, Dawdle.Backend.SQS,
    region: "us-east-1",
    queues: ["my-dawdle-queue-1", "my-dawdle-queue-2"]
```

Dawdle will randomly distribute work across the specified queues. For most
use cases one queue should be plenty.

## Setting Up Your SQS Queues

Obviously the configured SQS queues need to exist and be accessible by your
application. AWS authentication is handled by
[ex_aws](https://github.com/ex-aws/ex_aws). If you're already using `ex_aws` for
something else, your configuration should already be good. If not, follow the
configuration instructions on that page to set up your AWS key.

The queues themselves *must* be SQS's "Standard Queue" (not "FIFO Queue"). They
can be configured with default values, __except__ that:
* `Receive Message Wait Time` should be set to 20 seconds.

## Performance Considerations

The supplied callback is called by the same process which handles messages from
the SQS queue. In order to avoid blocking this process (and therefore delaying
further events), the callback should do as little work as possible - ideally
just firing a message to a different process.

## Use

Start the dawdle service (under one of your supervisors if applicable):

```elixir
iex> Dawdle.start_link()
{:ok, #PID<0.202.0>}
```

Create a callback function
```elixir
iex> callback = fn message -> IO.inspect "Received #{message}" end
#Function<6.99386804/1 in :erl_eval.expr/5>
```

Send your message
```elixir
iex(3)> Dawdle.call_after(callback, "Hello future", 2000)
:ok

# 2 seconds later
"Received Hello future"
```

Full docs can be found at
[https://hexdocs.pm/dawdle](https://hexdocs.pm/dawdle).

## Node Loss Tolerance

Because the timeouts are managed outside of your BEAM VM(s), they will be
preserved and handled by an available node even if the node that originally
set them no longer exists.

## Limits and Caveats

SQS standard queues are not millisecond-precision timing devices. Their
maximum delay precision is 1 second, so any timeouts given in fractions of a
second will be rounded down.

SQS standard queues guarantee *at least* once delivery. In practice it's almost
always exactly once, but your code needs to handle the possibility that a given
timeout will occur multiple times.

SQS does not guarantee ordering on its standard queues, so if you set two
timeouts with the same duration in quick succession, it's not guaranteed they'll
fire in the same order they were set.

SQS has an upper message size limit of 256KB, and the terms sent via it
are Base64 encoded, so avoid sending large structures in your message.
If you need a large bit of data as part of your message, stash it
in a persistent store first and send the key through Dawdle.

SQS timeouts are limited to 15 minutes. We handle longer timeouts by using
multiple chained messages, so factor this into any capacity calculations you're
doing.
