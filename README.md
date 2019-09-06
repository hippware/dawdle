# Dawdle

Dawdle weaponizes Amazon SQS for use in your Elixir applications. Use it when
you want to handle something later, or, better yet, when you want someone else
to handle it.

Put simply, you can use Dawdle to signal an event. That event can then be
handled by another process within the current Erlang node, or another node
altogether. You can even signal events with a delay, similar to
`Process.send_after/4`, but in a distributed and node-failure-tolerant manner.

The events are encoded and enqueued into Amazon AWS's Simple Queue Service
(SQS). This means that if, for example, you're running your BEAM system in a
Kubernetes cluster, and one or more of your pods die or are restarted or
terminated or what have you, your events will still fire and be handled
by whatever pods are available. If no pods are available for some reason,
the events will still be preserved and can be handled when a pod is
available again to service them.

## Installation

Add `dawdle` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dawdle, "~> 0.6.0"}
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

To disable the Dawdle queue listener on a node, use the following:

```elixir
config :dawdle,
    start_listener: false
```

You can also set the environment variables `DAWDLE_BACKEND` or
`DAWDLE_START_LISTENER`.

To configure your SQS queue, set the queue URL in `config.exs`:

```elixir
config :dawdle, Dawdle.Backend.SQS,
    region: "us-east-1",
    queue_url: "https://sqs.us-east-1.amazonaws.com/XXXXXXXXXXXX/my-dawdle-message-queue"
```

These values can also be set by using the environment variables
`DAWDLE_SQS_REGION` and `DAWDLE_SQS_QUEUE_URL`.

The configuration should be managed either via `config.exs` or by setting the
environment variables. Trying to mix the two will result in some changes being
overwritten in surprising ways. Caveat emptor.


## Setting Up Your SQS Queue

Obviously the configured SQS queue needs to exist and be accessible by your
application. AWS authentication is handled by
[ex_aws](https://github.com/ex-aws/ex_aws). If you're already using `ex_aws` for
something else, your configuration should already be good. If not, follow the
configuration instructions on that page to set up your AWS key.

Dawdle uses two queues: one for normal messages and one for delayed events. The
message queue *must* be a Standard Queue. They can be configured with default
values, __except__ that `Receive Message Wait Time` should be set to 20 seconds
to enable long polling. It is also a good idea to set `Default Visibility Timeout`
to a short value, like 2 seconds.

The queue can be created using the `aws` CLI or from the AWS Control Panel.

Here are example commands for creating the queue from the CLI:

```
$ aws sqs create-queue --queue-name my-dawdle-message-queue --attributes ReceiveMessageWaitTimeSeconds=20
{
    "QueueUrl": "https://xx-xxxx-x.queue.amazonaws.com/XXXXXXXXXXXX/my-dawdle-message-queue"
}
```

## Use

Full docs can be found at
[https://hexdocs.pm/dawdle](https://hexdocs.pm/dawdle).

Event handlers are where Dawdle really begins to shine. An event is essentially
just an Elixir struct. Define an event and event handler, then when you signal
that event using Dawdle, the event handler will be called to process the
event.

1. Define the event
```elixir
defmodule MyApp.TestEvent do
  defstruct :foo, :bar
end
```

2. Create an event handler
```elixir
defmodule MyApp.TestEventHandler do
  use Dawdle.Handler, only: [MyApp.TestEvent]

  alias MyApp.TestEvent

  def handle_event(%TestEvent{} = event) do
    IO.puts("Handling event #{inspect(event)}")
    :ok
  end
end
```

3. Signal an event
```elixir
t = %MyApp.TestEvent{foo: 1, bar: 2}

Dawdle.signal(t)
```

It is possible to signal an event that will bypass the queue and be delivered
directly to the appropriate handlers. The handlers will execute immediately on
the current node, but in a separate process. Simply pass `direct: true` to
`Dawdle.signal/2`:

```elixir
t = %MyApp.TestEvent{foo: 1, bar: 2}

Dawdle.signal(t, direct: true)
```

The event handler will execute on a node running the Dawdle application with
pollers enabled.

Note that if you are handling events on nodes different from where they are
signaled, then you need to ensure that the event definintions are available
in both places.


### Experimental API

There is a basic, experimental API which involves passing an anonymous 
function to `Dawdle.call/1`.  The function will execute on a node running the
Dawdle application with pollers enabled.

```elixir
iex> Dawdle.call(fn -> IO.puts("Hello World!") end)
:ok
Hello World!
```

Passing a function to `Dawdle.call_after/2` will result in that function being
called after the specified delay.

```elixir
iex> Dawdle.call_after(2000, fn -> IO.puts("Hello Future!") end)
:ok

# 2 seconds later
Hello Future!
```

This API is included for feedback and may be discontinued or extracted into a
separate library for Dawdle 1.0.


## Node Loss Tolerance

Because the events are managed outside of your BEAM VM(s), they will be
preserved and handled by an available node even if the node that originally
signaled them no longer exists.

## Limits and Caveats

Dawdle does not support FIFO queues. The cost paid for strict ordering is
reduced throughput and the possibility of the queue becoming clogged if an
event handler takes a long time. Dawdle resolves that tradeoff in favor of using
standard queues to maximize throughput and avoid queue clogs.

SQS standard queues are not millisecond-precision timing devices. Their
maximum delay precision is 1 second, so any timeouts given in fractions of a
second will be rounded down.

SQS standard queues guarantee *at least* once delivery. In practice it's almost
always exactly once, but your code needs to handle the possibility that a given
handler will execute multiple times.

SQS does not guarantee ordering on its standard queues, and Dawdle leverages
concurrency when dispatching events to handlers in order to keep latency low.
So if you signal two events in quick succession, it's not guaranteed that the
handlers will execute in the same order that the events were signaled.

SQS has an upper message size limit of 256KB, and the terms sent via it are
Base64 encoded, so avoid sending large structures in your message. If you need
a large bit of data as part of your message, stash it in a persistent store
first and send the key through Dawdle.

SQS delays are limited to 15 minutes. We handle longer delays by using
multiple chained messages, so factor this into any capacity calculations you're
doing.
