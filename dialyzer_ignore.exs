[
  # The use of GenServer.call confuses Dialyzer since that function returns any()
  {"lib/dawdle.ex", :contract_subtype},

  # Dialyzer thinks a module is actually a map
  {"lib/dawdle/backend/backend.ex", :missing_range, 27},

  # I am not matching the return value of an if clause, thankyouverymuch.
  {"lib/dawdle/client.ex", :unmatched_return, 73}
]
