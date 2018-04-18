use Mix.Config

config :dawdle, backend: Dawdle.Backend.SQS

config :dawdle, Dawdle.Backend.SQS,
  region: "us-east-1",
  # Add your SQS queues here
  queues: []
