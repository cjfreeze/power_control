defmodule PowerTest do
  use ExUnit.Case
  doctest PowerControl

  test "greets the world" do
    assert PowerControl.hello() == :world
  end
end
