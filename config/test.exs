use Mix.Config

# Sample config for running tests against SQS:
config :dawdle, Dawdle.Backend.SQS,
  region: "us-east-1",
  message_queue: "dawdle-test-1",
  delay_queue: "dawdle-test-2"
