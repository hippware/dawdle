use Mix.Config

config :dawdle,
    backend: Dawdle.Backend.SQS

config :dawdle, Dawdle.Backend.SQS,
    region: "us-east-1",
    queues: ["dawdle-test-1", "dawdle-test-2", "dawdle-test-3"], # Add your SQS queues here
    workers_per_queue: 1
