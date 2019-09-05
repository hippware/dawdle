defmodule Dawdle.MessageEncoder.TermTest do
  use ExUnit.Case

  alias Dawdle.MessageEncoder.Term

  @data "I sing the body electric"

  test "is reversible" do
    assert {:ok, encoded} = Term.encode(@data)
    assert {:ok, @data} = Term.decode(encoded)
  end

  test "unrecognized input" do
    assert {:error, :unrecognized} == Term.decode(@data)
  end
end
