use Mix.Config

config :dawdle, backend: Dawdle.Backend.Local

# Sample config for running tests against SQS:
config :dawdle, Dawdle.Backend.SQS,
  region: "us-east-1",
  queues: ["dawdle-test-1", "dawdle-test-2", "dawdle-test-3"]
