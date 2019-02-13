use Mix.Config

config :dawdle,
  backend: {:system, :module, "DAWDLE_BACKEND", Dawdle.Backend.SQS}

config :dawdle, Dawdle.Backend.SQS,
  region: "us-east-1",
  # Add your SQS queues here
  message_queue: "dawdle-message-queue",
  delay_queue: "dawdle-delay-queue"
