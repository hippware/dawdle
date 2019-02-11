use Mix.Config

config :dawdle,
  backend: {:system, :module, "DAWDLE_BACKEND", Dawdle.Backend.Local},
  start_listener: {:system, :boolean, "DAWDLE_START_LISTENER", true}

import_config "#{Mix.env()}.exs"
