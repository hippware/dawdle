defmodule Dawdle.Poller do
  alias Dawdle.Backend

  @callback child_spec({atom(), Backend.queue(), module()}) :: map()
end
