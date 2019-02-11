use Mix.Config

config :dawdle,
  backend: {:system, :module, "DAWDLE_BACKEND", Dawdle.Backend.Direct},
  start_listener: {:system, :boolean, "DAWDLE_START_LISTENER", true}

import_config "#{Mix.env()}.exs"
