defmodule Dawdle.MessageEncoder.TermTest do
  use ExUnit.Case

  alias Dawdle.MessageEncoder.Term

  @data "I sing the body electric"

  test "is reversible" do
    assert @data |> Term.encode() |> Term.decode() == @data
  end
end
