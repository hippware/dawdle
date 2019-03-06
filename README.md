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
    {:dawdle, "~> 0.5.0"}
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

To configure your SQS queues, set the following:

```elixir
config :dawdle, Dawdle.Backend.SQS,
    region: "us-east-1",
    delay_queue: "my-dawdle-delay-queue",
    message_queue: "my-dawdle-message-queue.fifo"
```

These values can also be set by using the environment variables
`DAWDLE_SQS_REGION`, `DAWDLE_SQS_DELAY_QUEUE`, and `DAWDLE_SQS_MESSAGE_QUEUE`.


## Setting Up Your SQS Queues

Obviously the configured SQS queues need to exist and be accessible by your
application. AWS authentication is handled by
[ex_aws](https://github.com/ex-aws/ex_aws). If you're already using `ex_aws` for
something else, your configuration should already be good. If not, follow the
configuration instructions on that page to set up your AWS key.

Dawdle uses two queues: one for normal messages and one for delayed events. The
message queue *must* be a FIFO Queue and the delay queue *must* be a Standard
Queue. They can be configured with default values, __except__ that
`Receive Message Wait Time` should be set to 20 seconds.

The queues can be created using the `aws` CLI or from the AWS Control Panel.

Here are example commands for creating the queues from the CLI:

```
$ aws sqs create-queue --queue-name my-dawdle-delay-queue --attributes ReceiveMessageWaitTimeSeconds=20
{
    "QueueUrl": "https://xx-xxxx-x.queue.amazonaws.com/XXXXXXXXXXXX/my-dawdle-delay-queue"
}

$ aws sqs create-queue --queue-name my-dawdle-message-queue.fifo --attributes FifoQueue=true,ReceiveMessageWaitTimeSeconds=20
{
    "QueueUrl": "https://xx-xxxx-x.queue.amazonaws.com/XXXXXXXXXXXX/my-dawdle-message-queue.fifo"
}
```

## Use

Full docs can be found at
[https://hexdocs.pm/dawdle](https://hexdocs.pm/dawdle).

### Basics

The most basic way to use Dawdle is to pass a simple function to
`Dawdle.call/1`.  The function will execute on a node running the Dawdle
application with pollers enabled.

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

### Event Handlers

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
  use Dawdle.Handler, types: [MyApp.TestEvent]

  alias MyApp.TestEvent

  def handle_event(%TestEvent{} = event) do
    IO.puts("Handling event #{inspect(event)}")
    :ok
  end
end
```

3. Register the event handler
```elixir
MyApp.TestEventHandler.register()
```

4. Signal an event
```elixir
t = %MyApp.TestEvent{foo: 1, bar: 2}

Dawdle.signal(t)
```

The event handler will execute on a node running the Dawdle application with
pollers enabled.

Note that if you are handling events on nodes different from where they are
signaled, then you need to ensure that the event definintions are available
in both places.

## Node Loss Tolerance

Because the events are managed outside of your BEAM VM(s), they will be
preserved and handled by an available node even if the node that originally
signaled them no longer exists.

## Limits and Caveats

SQS standard queues are not millisecond-precision timing devices. Their
maximum delay precision is 1 second, so any timeouts given in fractions of a
second will be rounded down.

SQS standard queues guarantee *at least* once delivery. In practice it's almost
always exactly once, but your code needs to handle the possibility that a given
delayed function call will execute multiple times.

SQS does not guarantee ordering on its standard queues, so if you set two
delayed function calls with the same duration in quick succession, it's not
guaranteed they'll execute in the same order they were set.

SQS has an upper message size limit of 256KB, and the terms sent via it
are Base64 encoded, so avoid sending large structures in your message.
If you need a large bit of data as part of your message, stash it
in a persistent store first and send the key through Dawdle.

SQS delays are limited to 15 minutes. We handle longer delays by using
multiple chained messages, so factor this into any capacity calculations you're
doing.
