use Mix.Config

config :dawdle,
  backend: {:system, :module, "DAWDLE_BACKEND", Dawdle.Backend.Local},
  start_listener: {:system, :boolean, "DAWDLE_START_LISTENER", true}

config :dawdle, Dawdle.Backend.SQS,
  region: {:system, "DAWDLE_SQS_REGION", "us-west-2"},
  delay_queue: {:system, "DAWDLE_SQS_DELAY_QUEUE", "dawdle-delay"},
  message_queue: {:system, "DAWDLE_SQS_MESSAGE_QUEUE", "dawdle-messages.fifo"}

import_config "#{Mix.env()}.exs"
